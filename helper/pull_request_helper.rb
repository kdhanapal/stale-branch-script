# frozen_string_literal: true

require 'httparty'
require_relative '../constant/stale_branch_constant'

# Helper module for Pull Request Related actions
module PullRequestHelper
  include StaleBranchConstant
  # Returns a list of branches that has open pull requests.
  def existing_open_pr_name
    exisintig_open_pr_name = []
    response = HTTParty.get(
      StaleBranchConstant::STALE_BRANCH_OPEN_PR_URL,
      headers: StaleBranchConstant::HEADERS
    )
    return unless response.any?

    response.each do |res|
      exisintig_open_pr_name << res['head']['ref']
    end
    exisintig_open_pr_name
  end

  # Returns a list of PR numbers of stale branches which has open PR's
  def existing_open_pr_number
    exisintig_open_pr_number = []
    response = HTTParty.get(
      StaleBranchConstant::STALE_BRANCH_OPEN_PR_URL,
      headers: StaleBranchConstant::HEADERS
    )
    return unless response.any?

    response.each do |res|
      exisintig_open_pr_number << res['number']
    end
    exisintig_open_pr_number
  end

  # Returns a JSON of post body needed to create pull request
  def create_pr_post_body(stale_branch)
    post_body = {
      title: StaleBranchConstant::PR_TITLE,
      body: StaleBranchConstant::PR_BODY,
      head: stale_branch,
      base: StaleBranchConstant::MASTER_BRANCH
    }
    post_body.to_json
  end

  # creates  pull request for the given stale branches
  def create_pull_request(pr_stale_branch_create_list)
    return unless pr_stale_branch_create_list.any?

    pr_stale_branch_create_list.each do |stale_branch|
      post_body = create_pr_post_body(stale_branch)
      HTTParty.post(
        StaleBranchConstant::POST_BASE_URL,
        body: post_body,
        headers: StaleBranchConstant::HEADERS
      )
    end
  end

  # closes the pull request for the given list of pull request numbers
  def close_pull_request(closing_pr_list)
    return unless closing_pr_list.present?

    closing_pr_list.each do |pr_number|
      patch_url = StaleBranchConstant::PATCH_PR_BASE_URL + pr_number.to_s
      HTTParty.patch(
        patch_url,
        body: StaleBranchConstant::PATCH_BODY,
        headers: StaleBranchConstant::HEADERS
      )
    end
  end
end
