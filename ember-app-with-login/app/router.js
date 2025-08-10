import EmberRouter from '@ember/routing/router';
import config from 'ember-app-with-login/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  this.route('splash', { path: '/' });
  this.route('authenticated');
});
