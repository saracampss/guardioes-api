require 'rails_helper'

def create_app
  App.new(:app_name => "brasil", :owner_country => "brasil").save()
end

def create_group(description, children_label, parent, save=false)
  group = Group.new(
    description: description, 
    parent_id: parent.id, 
    children_label: children_label
  )
  if save && !parent.children.where(description: description).any?
    group.save()
  else
    group = parent.children.where(description: description)[0]
  end
  group
end

def create_fga_group_tree
  Group::setup
  root = Group::get_root
  brasil = create_group('Brasil', children_label='Estado', parent=root, save=true)
  df = create_group('DF', children_label='Cidade', parent=brasil, save=true)
  gama = create_group('Gama', children_label='Instituição', parent=df, save=true)
  unb = create_group('UnB', children_label='Faculdade', parent=gama, save=true)
  create_group('FGA', nil, parent=unb, save=true)
end

def create_school_group_tree
  Group::setup
  root = Group::get_root
  brasil = create_group('Brasil', children_label='Estado', parent=root, save=true)
  df = create_group('DF', children_label='Cidade', parent=brasil, save=true)
  guara = create_group('Guara', children_label='Instituição', parent=df, save=true)
  seedf = create_group('SEEDF', children_label='Escola', parent=guara, save=true)
  create_group('Roga', nil, parent=seedf, save=true)
end

def create_group_manager(twitter=nil, require_id=nil, id_code_length=nil, save=false)
  group_manager = GroupManager.new(
    email: 'groupmanager@admin.com',
    password: '12345678',
    name: 'jose',
    vigilance_syndromes: [],
    twitter: twitter,
    require_id: require_id,
    id_code_length: id_code_length
  )
  if save
    group_manager.save()
  end
  group_manager
end

def connect_group_to_group_manager(group, group_manager)
  group.group_manager = group_manager
  group.save()
end

RSpec.describe Group, type: :model do
  before :all do
    create_app
  end

  before :each do
    Group.all.each do |g|
      g.delete_subtree
    end
  end
  
  describe "=> model functions" do
    context "=> static functions" do
      it "creates parent group" do
        Group::setup()
        expect(Group.last.description).to eq("root_node")
        expect(Group.last.children_label).to eq("Pais")
        expect(Group.last.parent_id).to eq(nil)
      end
      it "returns root group" do
        old_group_size = Group.count
        root = Group::get_root
        expect(root.description).to eq("root_node")
        expect(Group.count).to eq(old_group_size + 1)
      end
    end
      
    context '=> get_path' do
      it "when not labled string only" do
        unbfga = create_fga_group_tree
        unbfgapath = unbfga.get_path(string_only=true, labled=false)
        expect(unbfgapath.join('|')).to eq(
          "Brasil|DF|Gama|UnB|FGA"
        )
        school = create_school_group_tree
        schoolpath = school.get_path(string_only=true, labled=false)
        expect(schoolpath.join('|')).to eq(
          "Brasil|DF|Guara|SEEDF|Roga"
        )
      end
      it "when labled string only" do
        unbfga = create_fga_group_tree
        unbfgapath = unbfga.get_path(string_only=true, labled=true)
        expect(unbfgapath).to eq([
          {group: 'Brasil', label: 'Pais'},
          {group: 'DF', label: 'Estado'},
          {group: 'Gama', label: 'Cidade'},
          {group: 'UnB', label: 'Instituição'},
          {group: 'FGA', label: 'Faculdade'},
        ])
        school = create_school_group_tree
        schoolpath = school.get_path(string_only=true, labled=true)
        expect(schoolpath).to eq([
          {group: 'Brasil', label: 'Pais'},
          {group: 'DF', label: 'Estado'},
          {group: 'Guara', label: 'Cidade'},
          {group: 'SEEDF', label: 'Instituição'},
          {group: 'Roga', label: 'Escola'},
        ])
      end
      it "when not labled object" do
        unbfga = create_fga_group_tree
        unbfgapath = unbfga.get_path(string_only=false, labled=false)
        expect(unbfgapath).to eq([
          Group.find_by_description('Brasil'),
          Group.find_by_description('DF'),
          Group.find_by_description('Gama'),
          Group.find_by_description('UnB'),
          Group.find_by_description('FGA')
        ])
        school = create_school_group_tree
        schoolpath = school.get_path(string_only=false, labled=false)
        expect(schoolpath).to eq([
          Group.find_by_description('Brasil'),
          Group.find_by_description('DF'),
          Group.find_by_description('Guara'),
          Group.find_by_description('SEEDF'),
          Group.find_by_description('Roga')
        ])
      end
      it "when labled object" do
        unbfga = create_fga_group_tree
        unbfgapath = unbfga.get_path(string_only=false, labled=true)
        expect(unbfgapath).to eq([
          { group: Group.find_by_description('Brasil'), label: 'Pais' },
          { group: Group.find_by_description('DF'), label: 'Estado' },
          { group: Group.find_by_description('Gama'), label: 'Cidade' },
          { group: Group.find_by_description('UnB'), label: 'Instituição' },
          { group: Group.find_by_description('FGA'), label: 'Faculdade' },
        ])
        school = create_school_group_tree
        schoolpath = school.get_path(string_only=false, labled=true)
        expect(schoolpath).to eq([
          { group: Group.find_by_description('Brasil'), label: 'Pais' },
          { group: Group.find_by_description('DF'), label: 'Estado' },
          { group: Group.find_by_description('Guara'), label: 'Cidade' },
          { group: Group.find_by_description('SEEDF'), label: 'Instituição' },
          { group: Group.find_by_description('Roga'), label: 'Escola' },
        ])
      end
    end

    context '=> get_twitter' do 
      it 'when none is present (root twitter)' do
        fga = create_fga_group_tree
        expect(fga.get_twitter).to eq('appguardioes')
      end
      it 'when parent is present' do
        fga = create_fga_group_tree
        gm = create_group_manager(twitter='parenttwitter', save=true)
        connect_group_to_group_manager(fga.parent, gm)
        expect(fga.get_twitter).to eq('parenttwitter')
      end
      it 'when parent and grandparent node is present' do
        fga = create_fga_group_tree
        gm = create_group_manager(twitter='parenttwitter', save=true)
        gm2 = create_group_manager(twitter='grandparent', save=true)
        connect_group_to_group_manager(fga.parent, gm)
        connect_group_to_group_manager(fga.parent.parent, gm2)
        expect(fga.get_twitter).to eq('parenttwitter')
      end
      it 'when grandparent node is present' do
        fga = create_fga_group_tree
        gm = create_group_manager(twitter='grandparent', save=true)
        connect_group_to_group_manager(fga.parent.parent, gm)
        expect(fga.get_twitter).to eq('grandparent')
      end
      it 'when current node is present' do
        fga = create_fga_group_tree
        gm = create_group_manager(twitter='curenttwitter', save=true)
        connect_group_to_group_manager(fga, gm)
        expect(fga.get_twitter).to eq('curenttwitter')
      end
    end

    context '=> label' do
      it 'some node' do
        fga = create_fga_group_tree
        expect(fga.label).to eq('Faculdade')
        escola = create_school_group_tree
        expect(escola.label).to eq('Escola')
      end
    end

    context '=> delete_subtree' do
      it 'when leaf' do
        fga = create_fga_group_tree
        fga.delete_subtree
        expect(Group.count).to eq(5)
      end
      it 'when parent of leaf' do
        fga = create_fga_group_tree
        fga.parent.delete_subtree
        expect(Group.count).to eq(4)
      end
      it 'when country' do
        create_fga_group_tree
        country = Group::get_root.children.first
        country.delete_subtree
        expect(Group.count).to eq(1)
      end
      it 'when root' do
        fga = create_fga_group_tree
        Group.get_root.delete_subtree
        expect(Group.count).to eq(0)
      end
    end

    context '=> require_id' do
      it 'when it requires' do
        fga = create_fga_group_tree
        gm = create_group_manager(twitter=nil, require_id='codigo', save=true)
        connect_group_to_group_manager(fga, gm)
        expect(fga.require_id).to eq('codigo')
      end
      it 'when not specified (should be nil)' do
        fga = create_fga_group_tree
        expect(fga.require_id).to eq(nil)
      end
    end

    context '=> id_code_length' do
      it 'when has length' do
        fga = create_fga_group_tree
        gm = create_group_manager(save=true)
        gm.id_code_length = 3
        gm.save()
        connect_group_to_group_manager(fga, gm)
        expect(fga.id_code_length).to eq(3)
      end
      it 'when it does not have length' do
        fga = create_fga_group_tree
        expect(fga.id_code_length).to eq(nil)
      end
    end

  end

  describe "=> TDD US28" do
    context "=> achar usuario e suas notas" do
      before(:all) do 
        @email = 'alice@gmail.com'

        @app = App.create!(app_name: 'app', owner_country: 'brasil')

        @parent1 = Group.create!(description: 'root_node')
        @parent1 = @parent1.reload

        @group1 = Group.create!(description: 'brasil', parent_id: @parent1.id)
        @group1 = @group1.reload
        @user1 = User.create!(app_id: @app.id, user_name: 'alice', email: @email, password: "abc12345encryp", group: @group1)
        @user1.reload
        @syndrome1 = Syndrome.create!(threshold_score: 9.3.to_f)
        @syndrome1 = @syndrome1.reload
        @survey1 = Survey.create!(user_id: @user1.id, syndrome_id: @syndrome1.id, latitude: 22.44.to_f, longitude: 234.1.to_f)
        @survey1 = @survey1.reload

        @group2 = Group.create!(description: 'alemanha', parent_id: @parent1.id)
        @group2 = @group2.reload

        @group3 = Group.create!(description: 'grecia ', parent_id: @parent1.id)
        @group3 = @group3.reload
        @user3 = User.create!(app_id: @app.id, user_name: 'joao', email: 'joao@gmail.com', password: "abc12345encryp", group_id: @group3.id)
        @user3 = @user3.reload
        @syndrome3 = Syndrome.create!(threshold_score: 9.3.to_f)
        @syndrome3 = @syndrome3.reload
        @survey3 = Survey.create!(user_id: @user3.id, syndrome_id: @syndrome3.id, latitude: 24.44.to_f, longitude: 263.1.to_f) 
        @survey3 = @survey3.reload

        @expect1 = @group1.user_score_by_group_id.count
        @expect2 = @group2.user_score_by_group_id.count
        @expect3 = @group1.get_user_scores(@user1).count
        @expect4 = @group3.group_user_by_email(@email)
        @expect5 = @group1.group_user_by_email(@email)[:email]

        user_hash = @group1.group_user_by_email(@user1.email)
        user = User.find_by(email: user_hash[:email])  
        @except6 = user.group_id
      end 

      it '=> achar lista de usuários do grupo 1' do
        expect(@expect1).to eq(1)
      end 

      it '=> lista de usuários do grupo 2 vazia' do 
        expect(@expect2).to eq(0)
      end 
      
      it '=> busca notas do usuario' do
        expect(@expect3).to be > 0
      end 

      it '=> email passado como parametro nao pertence a um usuario associado ao group' do 
        expect(@expect4).to be nil
      end
      
      it '=> email do usuário retornado é igual ao email passado como parametro' do 
        expect(@expect5).to eq(@user1.email)
      end 
      
      it '=> group_id do user retornado é igual ao id do group' do 
        expect(@except6).to eq(@group1.id)
      end
    end
  end
end
