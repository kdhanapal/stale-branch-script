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
puts 'Collecting all the open PR info....'
open_pr_info = stale_branch_handler_object.list_all_open_pr
puts 'Open PR info collected!'
puts "Processing for the page: #{page_num}"
current_branches = stale_branch_handler_object.branches_report_per_page(page_num)
total_deleted_branches = 0
all_stale_branches = []

while current_branches[:b_r].any?
  existing_open_pr_branches = open_pr_info.keys
  stale_branches = stale_branch_handler_object.get_stale_branches(current_branches)
  (all_stale_branches << stale_branches).flatten!
  if stale_branches.any?
    stale_branches -= StaleBranchConstant::EXCLUDED_BRANCHES
    pr_qualified_stale_branches_list = stale_branch_handler_object.pr_qualified_stale_branches(
      stale_branches,
      existing_open_pr_branches
    )
    # EXCLUDED_BRANCHES is the list of branches to exclude from creating a PR.
    failed_pr_creation_branch_list = []
    if pr_qualified_stale_branches_list.present?
      pr_qualified_stale_branches_list -= StaleBranchConstant::EXCLUDED_BRANCHES
      puts 'Creating PR to the stale branches that do not have open PR...'
      failed_pr_creation_branch_list = stale_branch_handler_object.create_pull_request(pr_qualified_stale_branches_list, open_pr_info)
      puts 'Pull Request is created for the Stale Branches!'
    end
    if failed_pr_creation_branch_list.any?
      stale_branches -= failed_pr_creation_branch_list
    end
    # open_pr_info = stale_branch_handler_object.list_all_open_pr
    # collects open pr info and filters out non stale branches from being closed.
    qualified_closing_pr = stale_branch_handler_object.qualified_close_pr(stale_branches, open_pr_info)
    puts 'Closing the Stable Branches Open PR...'
    stale_branch_handler_object.close_pull_request(qualified_closing_pr, open_pr_info)
    puts 'Closed the PR for the given Stale Branches!'
    if stale_branches.any?
      puts 'Deleting the Stale Branches...'
      stale_branch_handler_object.delete_stale_branches(stale_branches)
      puts "Deleted the stale branches "
    else
      "No Stale branches to delete in this page"
    end
    total_deleted_branches += stale_branches.size
  else
    puts "No stale branches is present in this page"
  end
  page_num += 1
  puts "Processing for the page: #{page_num}"
  current_branches = stale_branch_handler_object.branches_report_per_page(page_num)
end

puts "all stale branches are "
puts all_stale_branches
puts "stale branch size is : #{all_stale_branches.size}"
puts "Total number of stale branches deleted is... #{total_deleted_branches}"
