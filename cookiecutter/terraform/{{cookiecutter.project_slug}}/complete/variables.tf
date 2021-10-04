variable "region" {
  type        = string
  description = "AWS Region"
}

{% for variable in cookiecutter.terraform.variables %}
variable "{{variable.name}}" {
  type        = {{variable.type}}
  description = "{{variable.description}}"
}
{% endfor %}