# frozen_string_literal: true

require 'httparty'
require_relative '../constant/stale_branch_constant'

# Helper module for Pull Request Related actions
module PullRequestHelper
  include StaleBranchConstant
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
  def create_pull_request(pr_stale_branch_create_list, open_pr_info)
    return unless pr_stale_branch_create_list.any?

    failed_pr_creation_branch_list = []
    pr_stale_branch_create_list.each do |stale_branch|
      begin
        post_body = create_pr_post_body(stale_branch)
        response = HTTParty.post(
          StaleBranchConstant::POST_BASE_URL,
          body: post_body,
          headers: StaleBranchConstant::HEADERS
        )
        if response.code == StaleBranchConstant::CREATE_RESPONSE_CODE
          response_body = JSON.parse(response.body)
          current_pr_number = response_body['number']
          open_pr_info[stale_branch] = current_pr_number
        else
          raise StandardError.new "PR creation failed for branch #{stale_branch}"
        end
      rescue StandardError => e
        puts e.message
        failed_pr_creation_branch_list << stale_branch
      end
      sleep 1
    end
    failed_pr_creation_branch_list
  end

  # closes the pull request for the given list of pull request numbers
  def close_pull_request(closing_pr_list, open_pr_info)
    return unless closing_pr_list.present?

    inverted_oper_pr_info = open_pr_info.invert
    closing_pr_list.each do |pr_number|
      current_branch = inverted_oper_pr_info[pr_number]
      patch_url = StaleBranchConstant::PATCH_PR_BASE_URL + pr_number.to_s
      response = HTTParty.patch(
        patch_url,
        body: StaleBranchConstant::PATCH_BODY,
        headers: StaleBranchConstant::HEADERS
      )

      if response.code == UPDATE_PR_RESPONSE_CODE
        open_pr_info.delete(current_branch)
      end
      sleep 0.5
    end
  end

  # Returns a list of stale branches to which are qualified to create a PR
  def pr_qualified_stale_branches(stale_branches, existing_open_pr_branches)
    pr_qualified_stale_branches_list = []
    return unless stale_branches.any?

    stale_branches.each do |stale_branch|
      if existing_open_pr_branches.nil?
        pr_qualified_stale_branches_list << stale_branch
      elsif existing_open_pr_branches.any? && !existing_open_pr_branches.include?(stale_branch)
        pr_qualified_stale_branches_list << stale_branch
      else
        next
      end
    end
    pr_qualified_stale_branches_list
  end

  # returns a list of pr numbers and filters out non stale branches from being closed.
  def qualified_close_pr(stale_branches, open_pr_map)
    qualified_closing_pr = []
    return unless stale_branches.any?

    # open_pr_names = open_pr_map.keys
    stale_branches.each do |stale_branch|
      qualified_closing_pr << open_pr_map[stale_branch]
    end
    qualified_closing_pr
  end

  # returns a list of open Pull Request for a given page
  def list_open_pr(page_num)
    list_open_pr_url = StaleBranchConstant::OPEN_PR_URL + page_num.to_s
    HTTParty.get(list_open_pr_url, headers: StaleBranchConstant::HEADERS)
  end

  # Returns list of all open Pull Request
  def list_all_open_pr
    page_num = 1
    open_pr_info_map = {}
    current_pull_requests = list_open_pr(page_num)
    while current_pull_requests.any?
      current_pull_requests.each do |open_pr_info|
        open_pr_info_map[open_pr_info['head']['ref']] = open_pr_info['number']
      end
      page_num += 1
      current_pull_requests = list_open_pr(page_num)
    end
    open_pr_info_map
  end
end
