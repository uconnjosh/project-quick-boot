import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { inject as service } from '@ember/service';

export default class FormRegister extends Component {
  @service store;
  @service fetch;

  @tracked email = '';
  @tracked name = '';
  @tracked organizationName = '';
  @tracked password = '';
  @tracked passwordConfirmation = '';
  @tracked isSubmitting = false;
  @tracked errors = {};

  @action
  updateEmail(event) {
    this.email = event.target.value;
  }

  @action
  updateName(event) {
    this.name = event.target.value;
  }

  @action
  updateOrganizationName(event) {
    this.organizationName = event.target.value;
  }

  @action
  updatePassword(event) {
    this.password = event.target.value;
  }

  @action
  updatePasswordConfirmation(event) {
    this.passwordConfirmation = event.target.value;
  }

  @action
  async submitForm(event) {
    event.preventDefault();
    
    if (this.isSubmitting) return;
    
    this.isSubmitting = true;
    this.errors = {};

    // Basic validation
    if (this.password !== this.passwordConfirmation) {
      this.errors.passwordConfirmation = "Passwords don't match";
      this.isSubmitting = false;
      return;
    }

    try {
      const adapter = this.store.adapterFor('application');
      const url = `${adapter.host}/auth/sign_up`;

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          user: {
            email: this.email,
            name: this.name,
            organization_name: this.organizationName || undefined,
            password: this.password,
            password_confirmation: this.passwordConfirmation
          }
        })
      });

      const data = await response.json();

      if (response.ok) {
        // Success - could emit an event or redirect
        if (this.args.onSuccess) {
          this.args.onSuccess(data);
        }
      } else {
        // Handle validation errors from Rails
        this.errors = data.errors || { general: 'Registration failed' };
      }
    } catch (error) {
      this.errors = { general: 'Network error. Please try again.' };
    } finally {
      this.isSubmitting = false;
    }
  }
}
