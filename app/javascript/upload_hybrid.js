document.addEventListener('DOMContentLoaded', function() {
    console.log('🚀 Upload hybrid загружен');
    initializeUploadHandler();
});

// Переинициализация после Turbo Stream обновлений
document.addEventListener('turbo:before-stream-render', function() {
    console.log('🔄 Turbo Stream обновляет DOM');
    // После обновления DOM переинициализируем обработчики
    setTimeout(() => {
        initializeUploadHandler();
    }, 100);
});

function initializeUploadHandler() {
    // Используем делегирование событий - слушаем на document
    document.removeEventListener('submit', handleFormSubmit, true);
    document.addEventListener('submit', handleFormSubmit, true);
}

function handleFormSubmit(event) {
    const form = event.target;

    // Проверяем, что это именно наша форма загрузки
    if (!form.id || form.id !== 'upload-form-element') {
        return; // Не наша форма, игнорируем
    }

    console.log('📤 Форма отправляется');
    event.preventDefault(); // Останавливаем стандартную отправку

    const fileInput = form.querySelector('input[type="file"]');
    const progressContainer = document.getElementById('upload-progress');
    const progressBar = document.getElementById('progress-bar');
    const progressText = document.getElementById('progress-text');

    // Проверяем, что все элементы найдены
    if (!fileInput) {
        console.log('❌ Поле файла не найдено');
        return;
    }

    if (!fileInput.files[0]) {
        alert('Выберите файл для загрузки');
        return;
    }

    if (!progressContainer || !progressBar || !progressText) {
        console.log('❌ Элементы progress bar не найдены');
        console.log('progressContainer:', progressContainer);
        console.log('progressBar:', progressBar);
        console.log('progressText:', progressText);
        return;
    }

    console.log('✅ Все элементы найдены, начинаем загрузку');

    // Показываем progress bar
    progressContainer.style.display = 'block';
    progressText.textContent = 'Загрузка: 0%';
    progressBar.style.width = '0%';
    progressBar.style.backgroundColor = '#007bff'; // Сброс цвета

    // Создаём XMLHttpRequest
    const xhr = new XMLHttpRequest();
    const formData = new FormData(form);

    // Отслеживаем прогресс
    xhr.upload.addEventListener('progress', function(event) {
        if (event.lengthComputable) {
            const percent = Math.round((event.loaded / event.total) * 100);
            progressBar.style.width = percent + '%';
            progressText.textContent = `Загрузка: ${percent}%`;
            console.log(`📊 Прогресс: ${percent}%`);
        }
    });

    // Обработка успешной загрузки
    xhr.addEventListener('load', function() {
        if (xhr.status === 200) {
            console.log('✅ Загрузка завершена успешно');
            progressText.textContent = 'Загрузка: 100%';

            // Обрабатываем Turbo Stream ответ
            const responseText = xhr.responseText;
            console.log('📄 Ответ сервера получен');

            if (responseText.includes('turbo-stream')) {
                console.log('🔄 Обрабатываем Turbo Stream');

                // Создаём временный контейнер
                const tempContainer = document.createElement('div');
                tempContainer.innerHTML = responseText;

                // Находим все turbo-stream элементы
                const turboStreams = tempContainer.querySelectorAll('turbo-stream');
                turboStreams.forEach(stream => {
                    document.body.appendChild(stream);
                });

                // Даём Turbo время обработать стримы
                setTimeout(() => {
                    turboStreams.forEach(stream => {
                        if (stream.parentNode) {
                            stream.parentNode.removeChild(stream);
                        }
                    });

                    // После обработки Turbo Stream переинициализируем обработчики
                    console.log('🔄 Переинициализируем обработчики');
                    initializeUploadHandler();
                }, 200);
            }

            // Скрываем progress bar
            setTimeout(() => {
                if (progressContainer) {
                    progressContainer.style.display = 'none';
                    progressBar.style.width = '0%';
                }
            }, 1500);

        } else {
            console.log('❌ Ошибка сервера:', xhr.status);
            progressText.textContent = 'Ошибка загрузки';
            progressBar.style.backgroundColor = '#dc3545';
        }
    });

    // Обработка ошибок
    xhr.addEventListener('error', function() {
        console.log('❌ Сетевая ошибка');
        progressText.textContent = 'Сетевая ошибка';
        progressBar.style.backgroundColor = '#dc3545';
    });

    // Отправляем запрос
    xhr.open('POST', form.action);
    xhr.setRequestHeader('Accept', 'text/vnd.turbo-stream.html');
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');

    const csrfToken = document.querySelector('meta[name="csrf-token"]');
    if (csrfToken) {
        xhr.setRequestHeader('X-CSRF-Token', csrfToken.content);
    }

    xhr.send(formData);
}
