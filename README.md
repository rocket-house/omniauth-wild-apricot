# OmniAuth WildApricot OAuth2 Strategy

Strategy to authenticate with WildApricot via OAuth2 in OmniAuth.

For more details, read the WildApricot docs: https://gethelp.wildapricot.com/en/articles/200-single-sign-on-service-sso

## Installation

First start by adding this gem to your Gemfile:

```ruby
gem 'omniauth-wild-apricot'
```

If you need to use the latest HEAD version, you can do so with:

```ruby
gem 'omniauth-wild-apricot', github: 'rocket-house/omniauth-wild-apricot'
```

Then `bundle install`.

## WildApricot API Setup

Go to 'https://myWAsite.com/admin/apps/integration/authorized-applications/' then:

* Select 'Authorize Application', then select 'Server Application'
* Name your application
* Select desired permission level: read/write
* Click 'Generate client secret'
* Select 'Authorize users via Wild Apricot single sign-on service'
* Fill in your app's redirect domain
* Take note of the following information:
  * Client ID
  * Client Secret

Additionally, you'll need your Wild Apricot Account # which can be found on the admin/billing page. You also need your site's url. If you're billing page is 'https://myWAsite.com/admin/billing/' then your site url is 'https://myWAsite.com/'.

The above information can be placed into your project's `.env` file (see `examples/.env-example`), or set as environment variables in your hosting provider's application settings.

## Usage using OmniAuth

Here's an example for adding the middleware to a Rails app in `config/initializers/omniauth.rb`. In this example, we are storing the key variables in the project's `.env` file (see `examples/.env-example`).

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :wild_apricot, ENV['WA_CLIENT_ID'], ENV['WA_CLIENT_SECRET'],
    {
      account_num: ENV['WA_ACCT_NUM'], # found at: https://myWAsite.com/admin/billing/
      site_url: ENV['WA_SITE_URL'],    # set to: 'https://myWAsite.com/'
      callback_path: '/path/to/callback'
    }
end
```

## Usage using Devise

If you are using [Devise](https://github.com/plataformatec/devise) then it will look like this:

```ruby
Devise.setup do |config|
  # other stuff...

  config.omniauth :wild_apricot, ENV['WA_CLIENT_ID'], ENV['WA_CLIENT_SECRET'],
    {
      account_num: ENV['WA_ACCT_NUM'], # found at: https://myWAsite.com/admin/billing/
      site_url: ENV['WA_SITE_URL']     # set to: 'https://myWAsite.com/'
    }

  # other stuff...
end
```

**NOTE:** If you are using this gem with devise with above snippet in `config/initializers/devise.rb` then do not create `config/initializers/omniauth.rb` which will conflict with devise configurations.

Then add the following to 'config/routes.rb' so the callback routes are defined.

```ruby
devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
```

Make sure your model is omniauthable. Generally this is "/app/models/user.rb"

```ruby
devise :omniauthable, omniauth_providers: [:wild_apricot]
```

Then make sure your callbacks controller is setup.

```ruby
# app/controllers/users/omniauth_callbacks_controller.rb:

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def wild_apricot
      # You need to implement the method below in your model (e.g. app/models/user.rb)
      @user = User.from_omniauth(request.env['omniauth.auth'])

      if @user.persisted?
        flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Wild Apricot'
        sign_in_and_redirect @user, event: :authentication
      else
        session['devise.wild_apricot_data'] = request.env['omniauth.auth'].except('extra') # Removing extra as it can overflow some session stores
        redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
      end
  end
end
```

and bind to or create the user

```ruby
def self.from_omniauth(access_token)
    data = access_token.info
    user = User.where(email: data['email']).first

    # Uncomment the section below if you want users to be created if they don't exist
    # unless user
    #     user = User.create(name: data['name'],
    #        email: data['email'],
    #        password: Devise.friendly_token[0,20]
    #     )
    # end
    user
end
```

For your views you can login using:

```erb
<%# omniauth-wild-apricot 1.0.x uses OmniAuth 2 and requires using HTTP Post to initiate authentication: %>
<%= link_to "Sign in with Wild Apricot", user_wild_apricot_omniauth_authorize_path, method: :post %>

<%# omniauth-wild-apricot prior 1.0.0: %>
<%= link_to "Sign in with Wild Apricot", user_wild_apricot_omniauth_authorize_path %>

<%# Devise prior 4.1.0: %>
<%= link_to "Sign in with Wild Apricot", user_omniauth_authorize_path(:wild_apricot) %>
```

An overview is available at https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview

## Auth Hash

Here's an example of an authentication hash available in the callback by accessing `request.env['omniauth.auth']`:

```ruby
{
  "provider":"wild_apricot",
  "uid":"50152421",
  "info":{
    "email":"anita.borg@example.com",
    "first_name":"Anita",
    "last_name":"Borg",
    "name":"Anita Borg"
  },
  "credentials":{
    "token":"thaXd6xjo4qpQnwraebbGA40vzg-",
    "refresh_token":"rt_2023-09-02_VguuDxHFznplhQk1YaOtNrxcgyk-",
    "expires_at":1693689961,
    "expires":true
  },
  "extra":{
    "raw_info":{
      "AdministrativeRoleTypes":["AccountAdministrator"],
      "FirstName":"Anita",
      "LastName":"Anita",
      "Email":"anita.borg@example.com",
      "DisplayName":"Anita, Anita",
      "PasswordExpiration":"2024-08-17T05:42:03+00:00",
      "MembershipLevel":{
        "Id":1253690,
        "Url":"https://api.wildapricot.org/v2/accounts/321456/MembershipLevels/1253690",
        "Name":"FREE"
      },
      "Status":"Active",
      "Id":50152421,
      "Url":"https://api.wildapricot.org/v2/accounts/321456/Contacts/50152421",
      "IsAccountAdministrator":true,
      "TermsOfUseAccepted":true
    }
  }
}
```

## Fixing Protocol Mismatch for `redirect_uri` in Rails

Just set the `full_host` in OmniAuth based on the Rails.env.

```
# config/initializers/omniauth.rb
OmniAuth.config.full_host = Rails.env.production? ? 'https://domain.com' : 'http://localhost:3000'
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Copyright (c) 2023 by Fred Zirdung

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
