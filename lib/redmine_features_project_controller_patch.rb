module RedmineFeaturesProjectControllerPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      before_action :calculate_time_account, :only => [:index,:show]
    end
  end
  module InstanceMethods
    def calculate_time_account
      prjs = []
      if @project.present?
        prjs = [@project]
      else
        prjs = Project.where(status: 1)
      end
      prjs.each do |project|
        total_time = 0
        issue_ids = project.issues.pluck(:id)
        unless issue_ids.blank?
          previous_spent = project.custom_field_value(27)
          billed_time = CustomValue.where(customized_type: 'Issue', customized_id: issue_ids, custom_field_id: 18).pluck(:value)
          billed_tot_mins = billed_time.map{|bill| (bill.to_f - bill.to_i)*100 }.sum
          billed_hours = billed_time.map(&:to_i).sum + (billed_tot_mins / 60)
          billed_mins = billed_tot_mins - ((billed_tot_mins / 60) * 60)
          Rails.logger.info "******billed #{project.id} #{billed_time} #{billed_hours} #{billed_mins}"
          training = CustomValue.where(customized_type: 'Issue', customized_id: issue_ids, custom_field_id: 19).pluck(:value)
          training_tot_mins = training.map{|train| (train.to_f - train.to_i)*100 }.sum
          training_hours = training.map(&:to_i).sum + (training_tot_mins / 60)
          training_mins = training_tot_mins - ((training_tot_mins/60) * 60)
          Rails.logger.info "******training #{project.id} #{training} #{training_hours} #{training_mins}"
          total_spent = project.time_entries.pluck(:hours)
          total_spent_tot_mins = total_spent.map{|spent| ((spent.to_f - spent.to_i) * 60).round }.sum
          total_spent_hours = total_spent.map(&:to_i).sum + (total_spent_tot_mins / 60)
          spent_mins = total_spent_tot_mins - ((total_spent_tot_mins/60) * 60)
          Rails.logger.info "******total_spent #{project.id} #{total_spent} #{total_spent_hours} #{spent_mins}"
          non_billable_hours = (total_spent_hours + training_hours) + ((training_mins + spent_mins) / 60)
          non_billable_mins = (training_mins + spent_mins) - (((training_mins + spent_mins) / 60) * 60)
          cv_hours = billed_hours - non_billable_hours
          cv_mins = billed_mins - non_billable_mins
          Rails.logger.info "******final #{project.id} #{non_billable_hours} #{non_billable_mins} #{cv_hours} #{cv_mins}"
          final_value = 0
          if cv_hours.negative?
            if cv_mins.positive?
              final_value = "#{cv_hours + 1}.#{60 + cv_mins}".to_f
            else
              final_value = "#{cv_hours}.#{cv_mins.abs}".to_f
            end
          else
            if cv_mins.zero? || cv_mins.positive?
              final_value = "#{cv_hours}.#{cv_mins}".to_f
            else
              final_value =  "#{cv_hours - 1}.#{60 - cv_mins}".to_f
            end
          end

          Rails.logger.info "******final #{final_value}"
          unless previous_spent.to_f == final_value
            cv = project.custom_values.detect{|c| c.custom_field_id == 27 }
            if cv.present?
              cv.value = final_value
              cv.save
            end
          end
        end
      end
    end
  end
end


unless ProjectsController.included_modules.include?(RedmineFeaturesProjectControllerPatch)
  ProjectsController.send(:include, RedmineFeaturesProjectControllerPatch)
end
