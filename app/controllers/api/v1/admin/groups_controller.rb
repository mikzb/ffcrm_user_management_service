# app/controllers/api/v1/admin/groups_controller.rb
class Api::V1::Admin::GroupsController < Api::V1::Admin::BaseController
  before_action :set_group, only: [:show, :update, :destroy]

  # GET /api/v1/admin/groups
  def index
    page     = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 25
    scope    = Group.order(id: :desc)

    groups = scope.offset((page - 1) * per_page).limit(per_page)
    total  = scope.count
    render json: {
      data: groups.map { |g| group_json(g) },
      pagination: { page: page, per_page: per_page, total: total }
    }
  end

  # GET /api/v1/admin/groups/:id
  def show
    render json: { data: group_json(@group) }
  end

  # POST /api/v1/admin/groups
  def create
    group = Group.new(group_params)
    if group.save
      render json: { data: group_json(group) }, status: :created
    else
      render json: { errors: group.errors }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/admin/groups/:id
  def update
    if @group.update(group_params)
      render json: { data: group_json(@group) }
    else
      render json: { errors: @group.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/admin/groups/:id
  def destroy
    if @group.destroy
      render json: { status: 'ok' }
    else
      render json: { errors: @group.errors }, status: :unprocessable_entity
    end
  end

  private

  def set_group
    @group = Group.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Group not found' }, status: :not_found
  end

  def group_params
    return {} unless params[:group]
    params.require(:group).permit(:name, user_ids: [])
  end

  def group_json(group)
    {
      id: group.id,
      name: group.name,
      user_ids: group.users.pluck(:id)
    }
  end
end