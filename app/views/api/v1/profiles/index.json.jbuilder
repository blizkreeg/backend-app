json.data do
  json._meta do
    json.city @city
  end
  json.items do
    json.array! @people do |person|
      json.firstname person.firstname
      json.age person.age
      json.profession person.profession
      json.location_city person.location_city
      json.questions_and_answers do
        json.array! person.qna do |hash|
          json.question hash[:question]
          json.answer hash[:answer]
        end
      end
      json.photo do
        json._meta do
          json.partial! 'api/v1/photos/meta'
        end
        json.partial! 'api/v1/photos/photo', photo: person.photo
      end
    end
  end
end
json.partial! 'api/v1/shared/auth'
