import { application } from "./application"

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Also load controllers from 'under' the "components" group
// eg "app_components" if components are in "app/components"
eagerLoadControllersFrom("app_components", application)
