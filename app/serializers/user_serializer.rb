class UserSerializer
  include JSONAPI::Serializer

  attributes :id, :username, :email, :first_name, :last_name,
             :title, :company, :alt_email, :phone, :mobile,
             :aim, :yahoo, :google, :skype

  # todo: more attributes can be added here as needed
  attribute :full_name do |user|
    user.full_name
  end
end