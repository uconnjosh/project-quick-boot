import DeviseAuthenticator from 'ember-simple-auth/authenticators/devise';

export default class DeviseAuthenticator extends DeviseAuthenticator {
  serverTokenEndpoint = "api/auth/sign_in";
}