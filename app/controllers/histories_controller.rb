class HistoriesController < ApplicationController
  doorkeeper_for :index, :show, scopes: %w(devices.read devices resources.read resources).map(&:to_sym)

  before_filter :find_owned_resources
  before_filter :find_resource,     only: %w(show)
  before_filter :search_params,     only: %w(index)
  before_filter :search_properties, only: %w(index)
  before_filter :pagination,        only: %w(index)

  def index
    @histories = @histories.limit(params[:per])
  end

  def show
  end

  private

  def find_owned_resources
    @histories = History.where(resource_owner_id: current_user.id)
  end

  def find_resource
    @history = @histories.find(params[:id])
  end

  def search_params
    @histories = @histories.where(device_id: find_id(params[:device])) if params[:device]
    @histories = @histories.gte(created_at: params[:from]) if params[:from]
    @histories = @histories.lte(created_at: params[:to])   if params[:to]
  end

  def search_properties(match = {})
    match.merge!({ property_id: Moped::BSON::ObjectId(find_id(params[:property])) }) if params[:property]
    match.merge!({ value: params[:value] }) if params[:value]
    match.merge!({ physical: params[:physical] }) if params[:physical]
    @histories = @histories.where('properties' => { '$elemMatch' => match })
  end

  def pagination
    params[:per] = (params[:per] || Settings.pagination.per).to_i
    params[:per] = Settings.pagination.per if params[:per] == 0 
    params[:per] = Settings.pagination.max_per if params[:per] > Settings.pagination.max_per
    @histories = @histories.gt(id: find_id(params[:start])) if params[:start]
  end
end
