json.data do
  json._meta do
    json.city @city
  end
  json.items do
    json.array! @profiles do |profile|
      json.firstname profile.firstname
      json.age profile.age
      json.profession profile.profession
      json.location_city profile.location_city
      json.questions_and_answers do
        # TBD: substitute qna collection object
        json.array!([1,2]) do |obj|
          json.question "What are some things you enjoy doing lorem ipsum lorem ipsum?"
          json.answer "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam blandit ac purus nec tincidunt."
        end
      end
      json.photo do
        json._meta do
          json.partial! 'api/v1/photos/meta'
        end
        if profile.photos.valid.first.blank?
          json.null!
        else
          json.partial! 'api/v1/photos/photo', photo: profile.photos.valid.first
        end
      end
    end
  end
end
json.partial! 'api/v1/shared/auth'
