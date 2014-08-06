class ClientsController < ApplicationController
  
  def index
    @clients = Client.all
  end

  def create
   
   name_file = save_file
    if name_file != false
      HardWorker.perform_async(name_file) 
              flash[:success] = 'Парсинг файла запущен'      
    end    
    redirect_to clients_path
  end

  def destroy
    @client = Client.find(params[:id])
    @client.destroy
    redirect_to clients_path
  end

  def cellular_number
    @cellular_numbers = set_cellular_number
  end

  def individual_detail
    @individual_details = set_individual_detail
  end

  private
  def client_params
    params.require(:client).permit(:client_number, :bill_number)
  end

  def set_cellular_number      
      CellularNumber.where(client_id:params[:id])
  end

  def set_individual_detail      
      IndividualDetail.where(client_id:params[:id])
  end

  def save_file
    uploaded_io = params[:client][:picture]
    if uploaded_io.content_type == 'application/pdf'       
      File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
        file.write(uploaded_io.read)   
      end
      return uploaded_io.original_filename
    else      
      flash[:danger] = 'Это не PDF файл' 
      return false
    end
  end

  

  
end
