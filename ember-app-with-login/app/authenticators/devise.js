import DeviseAuthenticator from 'ember-simple-auth/authenticators/devise';

export default class OAuth2Authenticator extends DeviseAuthenticator {
  serverTokenEndpoint = "http://localhost:3000/auth/sign_in";
}