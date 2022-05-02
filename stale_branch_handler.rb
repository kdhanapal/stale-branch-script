# frozen_string_literal: true

require 'httparty'
require 'time_difference'
require_relative './helper/list_branch_helper'
require_relative './constant/stale_branch_constant'
require_relative './helper/pull_request_helper'

# This class helps in cleaning up the stale branches in github
class StaleBranchHandler
  include StaleBranchConstant
  include PullRequestHelper
  include ListBranchHelper

  # Returns all the Stale Branches based on the STALE_BRANCH_TIME_UNIT_VALUE Defined.
  def get_stale_branches(branch_data)
    stale_branches = []
    return unless branch_data[:b_r].any?

    current_time = StaleBranchConstant::UTC_CURRENT_TIMESTAMP
    branch_data[:b_r].each do |row|
      current_stale_branch_time_unit = TimeDifference.between(
        row[:c_date], current_time
      ).send(StaleBranchConstant::TIME_DIFFERENCE_UNIT)
      if current_stale_branch_time_unit >= StaleBranchConstant::STALE_BRANCH_TIME_UNIT_VALUE && branch_not_whitelisted?(row[:name])
        stale_branches << row[:name]
      end
    end
    stale_branches
  end

  # Takes the Stale Branches as input and delete's them
  def delete_stale_branches(stale_branches)
    return unless stale_branches.any?

    stale_branches.each do |stale_branch|
      delete_url = StaleBranchConstant::DELETE_BRANCH_BASE_URL + stale_branch
      HTTParty.delete(delete_url, headers: StaleBranchConstant::HEADERS)
    end
  end
end

stale_branch_handler_object = StaleBranchHandler.new
page_num = 1
open_pr_info = stale_branch_handler_object.list_all_open_pr
existing_open_pr_branches = open_pr_info.keys
current_branches = stale_branch_handler_object.branches_report_per_page(page_num)
total_deleted_branches = 0

while current_branches.any?
  stale_branches = stale_branch_handler_object.get_stale_branches(current_branches)
  if stale_branches.present?
    stale_branches -= StaleBranchConstant::EXCLUDED_BRANCHES
    # existing_open_pr_branches = stale_branch_handler_object.existing_open_pr_name
    pr_qualified_stale_branches_list = stale_branch_handler_object.pr_qualified_stale_branches(
      stale_branches,
      existing_open_pr_branches
    )
    # EXCLUDED_BRANCHES is the list of branches to exclude from creating a PR.
    pr_qualified_stale_branches_list -= StaleBranchConstant::EXCLUDED_BRANCHES
    if pr_qualified_stale_branches_list.any?
      puts 'Creating PR to the stale branches that do not have open PR...'
      stale_branch_handler_object.create_pull_request(pr_qualified_stale_branches_list)
      puts 'Pull Request is created for the Stale Branches!'
    end
    open_pr_info = stale_branch_handler_object.list_all_open_pr
    # collects open pr info and filters out non stale branches from being closed.
    qualified_closing_pr = stale_branch_handler_object.qualified_close_pr(stale_branches, open_pr_info)
    puts 'Closing the Stable Branches Open PR...'
    stale_branch_handler_object.close_pull_request(qualified_closing_pr)
    puts 'Closed the PR for the given Stale Branches!'
    puts 'Deleting the Stale Branches...'
    stale_branch_handler_object.delete_stale_branches(stale_branches)
    puts "Deleted the stale branches "
    total_deleted_branches += stale_branches.size
  else
    puts "No more stale branches is present!"
    break
  end
  page_num += 1
  current_branches = stale_branch_handler_object.branches_report_per_page(page_num)
end

puts "Total number of stale branches deleted is... #{total_deleted_branches}"
