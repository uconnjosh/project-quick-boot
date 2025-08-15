import JSONAPIAdapter from '@ember-data/adapter/json-api';
import { inject as service } from '@ember/service';

export default class ApplicationAdapter extends JSONAPIAdapter {
  @service authenticationService;
  @service router;

  // host = 'http://127.0.0.1:3000';
  host = 'api';
  namespace = '';

  get headers() {
    return {
      Authorization: `Bearer ${localStorage.getItem(this.authenticationService.localStorageKey)}`,
    };
  }

  handleResponse(status, headers, payload, requestData) {
    if (status === 401) {
      localStorage.removeItem(this.authenticationService.localStorageKey);
      this.router.transitionTo('splash');
      return;
    }
    return super.handleResponse(status, headers, payload, requestData);
  }
}
