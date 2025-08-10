import JSONAPISerializer from '@ember-data/serializer/json-api';
import { camelize, underscore } from '@ember/string';
// import { underscore } from '@ember/string';
// import { camelize } from '@ember/string';

export default class ApplicationSerializer extends JSONAPISerializer {
  keyForAttribute(attr) {
    return underscore(attr); // Converts JS camelCase → snake_case (for requests)
  }

  keyForRelationship(key) {
    return underscore(key); // For related models
  }

  normalizeAttributeKey(key) {
    return camelize(key); // Converts API snake_case → JS camelCase (for responses)
  }
}
