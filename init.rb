Redmine::Plugin.register :new_features do
  name 'New Features plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  require 'redmine_features_project_controller_patch'
  Redmine::WikiFormatting::Macros.register do
    macro :timelog_table do |obj,args|
      if obj.blank?
        if self.assigns.present? && self.assigns["project"].is_a?(Project)
          project = self.assigns["project"]
        else
          return ''
        end
      elsif obj.is_a?(Issue)
        project = obj.project
      elsif obj.is_a?(Journal)
        project = obj.issue.project
      else
        return ''
      end
      x_day = args.second.present? ? Date.strptime(args.second,'%d-%m-%Y') : Time.new.to_date
      if args.first.blank?
	      x_time = x_day - 7.days
      elsif args.first.include? "-"
	      x_time =  Date.strptime(args.first,'%d-%m-%Y')
      else
	      x_time = x_day - args.first.to_i.days
      end
	    activity = TimeEntryActivity.where(name: 'Internal training').first
	    time_entries = project.time_entries.where("spent_on >= ? AND spent_on <= ? ", x_time,x_day).where.not(activity_id: activity.try(:id))
      user_entries = time_entries.group_by(&:user)
      html = "<table><th>User Name</th><th>Issue</th><th>Title</th><th>Total time</th>"
      user_entries.each do |user, entries|
	      entry_group = entries.group_by(&:issue)
	      entry_group.each do |issue, issue_entries|

		      html += "<tr><td>#{user.name}</td><td>#{issue.id}</td><td>#{issue.subject}</td><td>#{issue_entries.pluck(:hours).compact.sum}</td></tr>"
	      end
      end
      html += "<tr><th>Total</th><th colspan='4'>#{time_entries.pluck(:hours).compact.sum}</th>"
      html += "</table>"
      html.html_safe
    end
  end
end
