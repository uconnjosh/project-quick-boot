import DeviseAuthenticator from 'ember-simple-auth/authenticators/devise';

// todo fix the name
export default class OAuth2Authenticator extends DeviseAuthenticator {
  serverTokenEndpoint = "api/auth/sign_in";
}