
// TODO: probably remove me
import Service from '@ember/service';
import { inject as service } from '@ember/service';
import { action } from '@ember/object';

export default class AuthenticationServiceService extends Service {
  @service router;

  @service store;

  @action
  logout() {
    localStorage.removeItem(this.localStorageKey);
    this.router.transitionTo('splash');
  }

  get localStorageKey() {
    return 'emberAppWithLogin.authToken';
  }

  async login(email, password) {
    const adapter = this.store.adapterFor('application');
    const url = `${adapter.host}/auth/sign_in`;
    console.info('Logging in user at', url);
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(
        {
          user: {
            email,
            password
          }
        }
      )
    });
    
    const data = await response.json();
    if (response.ok) {
      localStorage.setItem(
        this.localStorageKey,
        {
          token: data.token,
          name: data.name,
          email: data.email
        }
      );
    } else {
      if (data.error === 'user_blocked') {
        this.userBlocked = true;
      }
    }

    return response;
  }
}
