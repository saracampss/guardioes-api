require 'rails_helper'
require 'byebug'

RSpec.describe GroupManagerTeam, type: :model do
  describe '#is_permitted?' do 
    before(:each) do 
      @app = App.create!(app_name: 'app', owner_country: 'brasil')
      @app = @app.reload
      @parent1 = Group.create!(description: 'root_node')
      @group_manager1 = GroupManager.create!(email: 'manager1@gmail.com', password: "abc12345encryp", vigilance_syndromes: [])
      @group_manager1 = @group_manager1.reload
      @group_manager2 = GroupManager.create!(email: 'manager2@gmail.com', password: "abc12345encryp", vigilance_syndromes: [])
      @group_manager2 = @group_manager2.reload
      @group_manager3 = GroupManager.create!(email: 'manager3@gmail.com', password: "abc12345encryp", vigilance_syndromes: [])
      @group_manager3 = @group_manager3.reload
      @group_manager4 = GroupManager.create!(email: 'manager4@gmail.com', password: "abc12345encryp", vigilance_syndromes: [])
      @group_manager4 = @group_manager4.reload
      @group1 = Group.create!(description: 'brasil', group_manager_id: @group_manager1.id, parent_id: @parent1.id)
      @group2 = Group.create!(description: 'colombia', group_manager_id: @group_manager2.id, parent_id: @parent1.id)
      @group3 = Group.create!(description: 'alemanha', parent_id: @parent1.id)
      @group4 = Group.create!(description: 'root_node', group_manager_id: @group_manager4.id, parent_id: @parent1.id)
      @manager_group_permission1 = ManagerGroupPermission.create!(group_manager_id: @group_manager1.id, group_id: @group1.id)
      @manager_group_permission2 = ManagerGroupPermission.create!(group_manager_id: @group_manager2.id, group_id: @group2.id)
      @manager_group_permission3 = ManagerGroupPermission.create!(group_manager_id: @group_manager3.id, group_id: @group3.id)
      @group_manager_team1 = GroupManagerTeam.create!(email: 'manager1@gmail.com', password: 'abc12345', group_manager_id: @group_manager1.id, app_id: @app.id)
      @group_manager_team1 = @group_manager_team1.reload
      @group_manager_team2 = GroupManagerTeam.create!(email: 'manager2@gmail.com', password: 'abc12345', group_manager_id: @group_manager2.id, app_id: @app.id)
      @group_manager_team2 = @group_manager_team2.reload
      @group_manager_team3 = GroupManagerTeam.create!(email: 'manager3@gmail.com', password: 'abc12345', group_manager_id: @group_manager3.id, app_id: @app.id)
      @group_manager_team3 = @group_manager_team3.reload
      @group_manager_team4 = GroupManagerTeam.create!(email: 'manager4@gmail.com', password: 'abc12345', group_manager_id: @group_manager4.id, app_id: @app.id)
      @group_manager_team4 = @group_manager_team4.reload
      @permission1 = Permission.create!(models_manage: ['message', 'form'], group_manager_id: @group_manager1.id, group_manager_team_id: @group_manager_team1.id)
      @permission2 = Permission.create!(models_manage: ['message', 'group'], group_manager_id: @group_manager2.id, group_manager_team_id: @group_manager_team2.id)
      @permission3 = Permission.create!(models_manage: ['group', 'message', 'form'], group_manager_id: @group_manager3.id, group_manager_team_id: @group_manager_team3.id)      
    end

    it 'caso 1' do
      expect(@group_manager_team1.is_permitted?(@group1)).to be false 
    end

    it 'caso 2' do
      expect(@group_manager_team2.is_permitted?(@group2)).to be true
    end 

    it 'caso 3' do 
      expect(@group_manager_team3.is_permitted?(@group2)).to be false
    end
    
    it 'caso 4' do 
      expect(@group_manager_team4.is_permitted?(@group4)).to be false
    end 

  end 
end
