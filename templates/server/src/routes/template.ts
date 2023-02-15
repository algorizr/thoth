import express from 'express';
import { validate } from '../middlewares';
import { {{ name | lower }}Validators } from '../validators';
import { taskController } from '../controllers';
import sse from '../utils/sse';

const {{ name | lower }}Router = express.Router();

{{ name | lower }}Router.get('/events', sse.init);
{{ name | lower }}Router.get('/:id/events', sse.init);

{% for route in list %}
{{ name | lower }}Router.
{% if route.type == "findMany" or route.type == "findUnique" %}
get
{% elif route.type == "create" %}
post
{% elif route.type == "update" %}
put
{% elif route.type == "delete" %}
delete
{% endif %}
(
  '/{% if route.where %}:{{ route.where }}{% endif %}',
  validate({{ name | lower }}Validators.{{ route.id }}Validator),
  {{ name | lower }}Controller.{{ route.id }},
);
{% endfor %}

export default taskRouter;
