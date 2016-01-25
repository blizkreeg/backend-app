json.data do
  json.array! @profiles do |profile|
    json.firstname profile.firstname
    json.age profile.age
    json.profession profile.profession
    json.questions_and_answers do
      # TBD: substitute qna collection object
      json.array!([1,2]) do |obj|
        json.question "What are some things you enjoy doing lorem ipsum lorem ipsum?"
        json.answer "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam blandit ac purus nec tincidunt."
      end
    end
    json.photo do
      if profile.photos.valid.first.blank?
        json.null!
      else
        json.partial! 'photo', photo: profile.photos.valid.first
      end
    end
  end
end
