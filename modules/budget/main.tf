resource "azurerm_consumption_budget_subscription" "this" {
  name            = var.budget_name
  subscription_id = var.subscription_id

  amount     = var.amount
  time_grain = "Monthly"

  time_period {
    start_date = var.start_date
    end_date   = var.end_date
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 50
    threshold_type = "Actual"

    contact_emails = var.contact_emails
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 75
    threshold_type = "Actual"

    contact_emails = var.contact_emails
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 90
    threshold_type = "Actual"

    contact_emails = var.contact_emails
  }

  notification {
    enabled        = true
    operator       = "GreaterThanOrEqualTo"
    threshold      = 100
    threshold_type = "Actual"

    contact_emails = var.contact_emails
  }

  notification {
    enabled        = true
    operator       = "GreaterThan"
    threshold      = 80
    threshold_type = "Forecasted"

    contact_emails = var.contact_emails
  }
}