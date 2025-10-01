class Api::V1::Admin::UsersController < Api::V1::Admin::BaseController
  before_action :set_user, only: [:show, :update, :destroy, :suspend, :reactivate]

  # GET /api/v1/admin/users
  def index
    page     = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 25
    scope    = User.order(id: :desc)

    if params[:q].present?
      scope = scope.merge(User.ransack(params[:q]).result)
    end
    if params[:query].present?
      scope = scope.text_search(params[:query])
    end

    users  = scope.offset((page - 1) * per_page).limit(per_page)
    total  = scope.count

    render json: {
      data: users.map { |u| UserSerializer.new(u).serializable_hash },
      pagination: { page: page, per_page: per_page, total: total }
    }
  end

  # GET /api/v1/admin/users/:id
  def show
    render json: UserSerializer.new(@user).serializable_hash
  end

  # POST /api/v1/admin/users
  def create
    user = User.new(user_params)
    user.suspend_if_needs_approval
    if user.save
      render json: { data: UserSerializer.new(user).serializable_hash }, status: :created
    else
      render json: { errors: user.errors }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/admin/users/:id
  def update
    if @user.update(user_params)
      render json: { data: UserSerializer.new(@user).serializable_hash }
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/admin/users/:id
  def destroy
    unless @user.destroyable?(current_user)
      return render json: { warning: I18n.t(:msg_cant_delete_user, @user.full_name) }, status: :unprocessable_entity
    end

    if @user.destroy
      render json: { status: 'ok' }
    else
      render json: { errors: @user.errors }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/admin/users/:id/suspend
  def suspend
    @user.update_attribute(:suspended_at, Time.now) if @user != current_user
    render json: { data: UserSerializer.new(@user).serializable_hash }
  end

  # PUT /api/v1/admin/users/:id/reactivate
  def reactivate
    @user.update_attribute(:suspended_at, nil)
    render json: { data: UserSerializer.new(@user).serializable_hash }
  end

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  def user_params
    return {} unless params[:user]
    p = params.require(:user).permit(
      :admin, :username, :email, :first_name, :last_name, :title, :company,
      :alt_email, :phone, :mobile, :aim, :yahoo, :google, :skype,
      :password, :password_confirmation, group_ids: []
    )
    p[:password_confirmation] = nil if p[:password_confirmation].is_a?(String) && p[:password_confirmation].strip == ''
    p
  end
end