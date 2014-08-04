class ClientsController < ApplicationController
  
  def index
    @clients = Client.all
  end

  def new
  end

  def create
    contents = open_file
    if contents == false        
      redirect_to new_client_path
    else      
      parse = parse_file(contents)
      if parse == false
        flash[:error] = 'Это другой PDF файл'  
        redirect_to new_client_path
      else          
        @client = save_db(parse)
        @client.save
        redirect_to clients_path
      end
    end
        
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

  def open_file
    uploaded_io = params[:client][:picture]
    if uploaded_io.original_filename[-4..-1] == '.pdf'       
      File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
        file.write(uploaded_io.read)   
      end
      all_content="" 
        reader = PDF::Reader.new("public/uploads/#{uploaded_io.original_filename}")       
        reader.pages.each do |page|
          all_content = all_content + page.text
        end
        return all_content.split('PAGE ')       
    else      
      flash[:error] = 'Это не PDF файл' 
      return false
    end
  end
  
  def parse_file(contents)
    if contents[0].slice(/CLIENT\W+N\W+\w+/).to_s.empty? 
      return false
    else
      client = contents[0].slice(/CLIENT\W+N\W+\w+/).slice(/\d+/).to_i
      bill = contents[0].slice(/BILL\WN\W+\w+/).slice(/\d+/).to_i
      j = 0
      data = [] 
      saving = []
      total_current_charges = []      
      total = []
      parse = {service_plan_name: [/Service Plan Name/], additional_local_airtime:  [/Additional Local Airtime/],
      long_distance_charges: [/Long Distance Charges/], data_and_other_services: [/Data and Other Services/],
      value_addded_services: [/Value Added Services/]}
      contents.each do |content|
        exit = content.scan(/I\WN\WD\WI\WV\WI\WD\WU\WA\WL\WD\WE\WT\WA\WI\WL/)
        if exit.empty?        
          data += content.scan(/\w+\W+\d+\-\d+\-\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+/)
        elsif exit.empty? == false && j < 5       
          if content.slice(/C u r r e n t C h a r g e s - D e t a i l/).nil? == false 
            j += 1      
            page = content.slice(/\d+\W+of\W+\d+/).slice(/\d+/).to_i
            # Total Month's Savings
            if content.slice(/Total\W+Month's\W+Savings\W+\d+.\d+/).nil?
              saving.push(0)
            else
              saving.push(content.slice(/Total\W+Month's\W+Savings\W+\d+.\d+/).slice(/\d+.\d+/).to_i)
            end
            # Total Current Charges
            if content.slice(/Total Current Charges\W+\d+.\d+/).nil?
              total_current_charges.push(0)
            else
              total_current_charges.push(content.slice(/Total Current Charges\W+\d+.\d+/).slice(/\d+.\d+/).to_i)
            end       
            # service_plan_name, additional_local_airtime, long_distance_charges, data_and_other_services, value_addded_services
            parse.each_key do |key|
              if content.slice(parse[key][0]).nil?
                parse[key].push(0)
              else
                parse[key].push(true)
              end
            end           
            # Total
            total.push(content.scan(/Total\W+\$ \d+.\d+/))
            total[j-1].map! do |k|
              k.slice(/\d+.\d+/)
            end     
          end
        else j >= 5       
          break       
        end
      end  
      data.map! do |i|
        i.split
      end
      parse.each_key do |key|
        parse[key].delete_at(0)
      end   
      parse[:client] = client
      parse[:bill] =  bill
      parse[:data] = data
      parse[:saving] =  saving
      parse[:total_current_charges] =  total_current_charges
      parse[:total] =  total  
      return parse
    end  
  end

  def save_db(parse)
    client = Client.new(client_number:parse[:client], bill_number:parse[:bill] )
    parse[:data].each do |dataa|
      cellular_number = CellularNumber.new
      cellular_number.user = dataa[1]
      cellular_number.service_plan_price = dataa[2].to_f
      cellular_number.additional_local_airtime = dataa[3].to_f
      cellular_number.ld_and_roaming_charges = dataa[4].to_f
      cellular_number.data_voice_and_other = dataa[5].to_f
      cellular_number.other_frees = dataa[9].to_f
      cellular_number.gst = dataa[12].to_f
      cellular_number.subtotal = dataa[11].to_f
      cellular_number.total = dataa[13].to_f   
      client.cellular_numbers << cellular_number  
    end  
    parse[:saving].each_index do |i|
      individual_detail = IndividualDetail.new
      individual_detail.total_onths_savings = parse[:saving][i].to_f
      individual_detail.total = parse[:total_current_charges][i].to_f
      j = 0
      if parse[:service_plan_name][i] == true
        individual_detail.service_plan_name = parse[:total][i][j].to_f
        j += 1
      else 
        individual_detail.service_plan_name = parse[:service_plan_name][i]
      end
      if parse[:additional_local_airtime][i] == true
        individual_detail.additional_local_airtime = parse[:total][i][j].to_f
        j += 1
      else 
        individual_detail.additional_local_airtime = parse[:additional_local_airtime][i]
      end
      if parse[:long_distance_charges][i] == true
        individual_detail.long_distance_charges = parse[:total][i][j].to_f
        j += 1
      else 
        individual_detail.long_distance_charges = parse[:long_distance_charges][i]
      end
      if parse[:data_and_other_services][i] == true
        individual_detail.data_and_other_services = parse[:total][i][j].to_f
        j += 1
      else 
        individual_detail.data_and_other_services = parse[:data_and_other_services][i]
      end
      if parse[:value_addded_services][i] == true
        individual_detail.value_addded_services = parse[:total][i][j].to_f
        j += 1
      else 
        individual_detail.value_addded_services = parse[:value_addded_services][i]
      end
       client.individual_details << individual_detail 
    end
    client
  end

end
