import Route from '@ember/routing/route';

export default class SplashRoute extends Route {
  setupController(controller, model) {
    super.setupController(controller, model);
    controller.set('didRequestCode', null);
    controller.set('userEnteredEmail', null);
    controller.set('userEnteredCode', null);
    controller.set('saltFromServer', null);
  }
}
