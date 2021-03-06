class ClientsController < ApplicationController
before_action :authenticate_user!

  def index 
    @clients = Client.paginate(page: params[:page], :per_page => 10)
    gon.global.jid[0] = nil
  end

  def create   
   name_file = save_file
   if name_file != false
      @jid = HardWorker.perform_async(name_file) 
      gon.global.jid.push(@jid)
      gon.global.name_pdf_file.push(name_file)  
      
   end
   #@clients = Client.paginate(page: params[:page], :per_page => 10)
   #@data={us: @jid}
   #render json: @data, status: :ok, location: clients_path
   redirect_to clients_path

  end

  def destroy
    @client = Client.find(params[:id])
    @client.destroy
    redirect_to clients_path
  end

  def cellular_number
    @cellular_numbers = CellularNumber.where(client_id:params[:id]).paginate(page: params[:page], :per_page => 20)
    p current_user
  end

  def individual_detail
    @individual_details = IndividualDetail.where(client_id:params[:id])
  end


  def qwerty
  key =  params[:key].to_i
   p key
  if gon.global.jid[key].nil?
    gon.global.jid.delete_at(key)
    @data={status_sidekiq: 'complete', keyy: key}
    @data
  elsif SidekiqStatus::Container.load(gon.global.jid[key]).status.to_s == 'complete'
    gon.global.jid.delete_at(key)
    gon.global.name_pdf_file.delete_at(key)
    gon.global.user.delete_at(key)
    @data={status_sidekiq: 'complete', keyy: key}
    @data
  else   
    @data={status_sidekiq: SidekiqStatus::Container.load(gon.global.jid[key]).status, keyy: key}
  p @data
  end
  render :json => @data, status: :ok
  end

  private
  def client_params
    params.require(:client).permit(:client_number, :bill_number)
  end  

  def save_file
    uploaded_io = params[:client][:pdf_file]
    gon.global.user.push(params['authenticity_token'])
    if  /.pdf\z/ === uploaded_io.original_filename
      
      File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
        file.write(uploaded_io.read)   
      end
      return uploaded_io.original_filename
    else      
      flash.now[:danger] = 'Это не PDF файл' 
      return false
    end
  end
  

end
