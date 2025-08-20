# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
#небольшой комментик, я пропробовал выполнить несколько раз bin/rails db:seed ради интереса и наплодил целую тучу файлов, поэтому и добавил destroy_all
#Document.destroy_all
Document.create!(name: "Первый документ")
Document.create!(name: "Второй документ")
Document.create!(name: "Третий документ")
Document.create!(name: "Четвёртый документ")
Document.create!(name: "Пятый документ")
Document.create!(name: "Шестой документ")

puts "Создано #{Document.count} документов для демонстрации интерфейса"