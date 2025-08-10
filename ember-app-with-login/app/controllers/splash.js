import Controller from '@ember/controller';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import { inject as service } from '@ember/service';

export default class SplashController extends Controller {
  @service authenticationService;
  @service session;
  @service store;
  @service router;
  @tracked userEnteredEmail;
  @tracked userEnteredPassword;

  @action
  async login() {
    await this.session.authenticate('authenticator:devise', this.userEnteredEmail, this.userEnteredPassword)
    
    if (this.session.isAuthenticated) {
      this.router.transitionTo('authenticated');
    }
  }

  get didEnterValidEmail() {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.userEnteredEmail ?? '');
  }

  get didEnterValidPassword() {
    return this.userEnteredPassword && this.userEnteredPassword.length >= 8;
  }

  get didEnterValidCode() {
    return this.userEnteredCode && this.userEnteredCode.length === 6;
  }
}
