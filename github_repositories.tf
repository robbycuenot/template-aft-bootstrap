resource "github_repository" "aft-account-customizations" {
  name        = local.repos.aft-account-customizations.repo_name
  description = "Repository for ${local.repos.aft-account-customizations.repo_name}"
  visibility  = "private"
  has_downloads = true
  has_issues  = true
  has_projects = true
  has_wiki    = true

  template {
    owner = local.templates_organization
    repository = local.repos.aft-account-customizations.template_name
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository" "aft-account-provisioning-customizations" {
  name        = local.repos.aft-account-provisioning-customizations.repo_name
  description = "Repository for ${local.repos.aft-account-provisioning-customizations.repo_name}"
  visibility  = "private"
  has_downloads = true
  has_issues  = true
  has_projects = true
  has_wiki    = true

  template {
    owner = local.templates_organization
    repository = local.repos.aft-account-provisioning-customizations.template_name
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository" "aft-account-requests" {
  name        = local.repos.aft-account-requests.repo_name
  description = "Repository for ${local.repos.aft-account-requests.repo_name}"
  visibility  = "private"
  has_downloads = true
  has_issues  = true
  has_projects = true
  has_wiki    = true

  template {
    owner = local.templates_organization
    repository = local.repos.aft-account-requests.template_name
  }

  lifecycle {
    prevent_destroy = true
  }
}


resource "github_repository" "aft-framework" {
  name        = local.repos.aft-framework.repo_name
  description = "Repository for ${local.repos.aft-framework.repo_name}"
  visibility  = "private"
  has_downloads = true
  has_issues  = true
  has_projects = true
  has_wiki    = true

  template {
    owner = local.templates_organization
    repository = local.repos.aft-framework.template_name
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository" "aft-global-customizations" {
  name        = local.repos.aft-global-customizations.repo_name
  description = "Repository for ${local.repos.aft-global-customizations.repo_name}"
  visibility  = "private"
  has_downloads = true
  has_issues  = true
  has_projects = true
  has_wiki    = true

  template {
    owner = local.templates_organization
    repository = local.repos.aft-global-customizations.template_name
  }

  lifecycle {
    prevent_destroy = true
  }
}