class RentalsController < ApplicationController
  def checkout
    rental = Rental.new(rental_params)
    rental.setup_dates
    
    if rental.valid?
      if rental.movie.check_inventory
        if rental.save
          rental.movie.decrease_inventory
          rental.customer.increase_movies_checkout
          render json: rental.as_json(only: [:customer_id, :movie_id]), status: :ok
          return
        else
          render json: { ok: false, errors: "Rental cannot be created!" }, status: :bad_request
          return
        end
      else
        render json: { ok: false, errors: "Stock unavailable!" }, status: :bad_request
      end
    else
      render json: { ok: false, errors: rental.errors.messages }, status: :bad_request
    end
  end
  
  def checkin
    rental = Rental.find_by(rental_params)
    if rental
      rental.movie.increase_inventory
      rental.customer.decrease_movies_checkout
      rental.rental_overdue
      
      render json: rental.as_json(only: [:customer_id, :movie_id]), status: :ok
      return
    else
      render json: { ok: false, errors: "Rental is not found!" }, status: :bad_request
      return
    end
  end
  
  def overdue
    rentals = Rental.where(is_overdue: true)
    
    if params[:p] || params[:n]
      rentals = rentals.paginate(page: params[:p], per_page: params[:n])
    end
    
    json_body = []
    
    rentals.each do |rental|
      json_body << {
      "movie_id" => rental.movie_id,
      "title" => rental.movie.title,
      "customer_id" => rental.customer_id,
      "name" => rental.customer.name,
      "postal_code" => rental.customer.postal_code,
      "checkout_date" => rental.check_out,
      "due_date" => rental.check_in}  
    end
    
    if params[:sort]
      json_body = json_body.sort_by{|rental| rental[params[:sort]]}
    end
    
    if json_body.empty?
      render json: { messages: "No overdue rental is found!" }, status: :ok
      return
    else
      render json: json_body, status: :ok
      return
    end
    
  end
  
  private
  
  def rental_params
    params.permit(:customer_id, :movie_id)
  end
  
end
