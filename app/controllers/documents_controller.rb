class DocumentsController < ApplicationController
  def index
    @documents = Document.order(created_at: :desc)
    @document = Document.new
  end
  #def new
  # @document = Document.new
  #end
  def create
    @document = Document.new(document_params)
    if @document.name.blank? && @document.file.attached?
      @document.name = @document.file.filename.to_s
    end
    if @document.save
      @documents = Document.order(created_at: :desc)
      respond_to do |format|
        format.html { redirect_to documents_path, notice: 'Документ успешно загружен!' }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("documents-list",
                                 partial: "documents_list",
                                 locals: { documents: @documents }),
            turbo_stream.replace("upload-form",
                                 partial: "upload_form",
                                 locals: { document: Document.new })
          ]
        end
      end
    else
      @documents = Document.order(created_at: :desc)
      respond_to do |format|
        format.html { redirect_to documents_path, alert: 'Ошибка загрузки файла' }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("upload-form",
                                                    partial: "upload_form",
                                                    locals: { document: Document.new })
        end
      end
    end
  end
  def show
    @document = Document.find(params[:id])
    unless @document.file.attached?
      redirect_to documents_path, alert: 'Файл не найден'
      return
    end
    send_data @document.file.download,
              filename: @document.file.filename.to_s,
              type: @document.file.content_type,
              disposition: 'attachment'
  end
  private
  def document_params
    params.require(:document).permit(:name, :file)
  end
end
