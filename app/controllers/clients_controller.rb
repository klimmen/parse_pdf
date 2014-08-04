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
        @client =  new_db_client(parse[:client], parse[:bill])
        parse[:data_cellular_numbers].each do |data_cellular_number|
          @client.cellular_numbers << new_db_cellular_number(data_cellular_number)
        end
        parse[:saving].each_index do |i|
          @client.individual_details << new_db_individual_detail(parse[:saving][i], 
              parse[:total_current_charges][i], parse[:service_plan_name][i], 
              parse[:additional_local_airtime][i], parse[:long_distance_charges][i],
              parse[:data_and_other_services][i], parse[:value_addded_services][i])
        end
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
    if uploaded_io.original_filename[-4..-1].downcase == '.pdf'       
      File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
        file.write(uploaded_io.read)   
      end
      all_content=[] 
        reader = PDF::Reader.new("public/uploads/#{uploaded_io.original_filename}")       
        reader.pages.each do |page|
          all_content.push(page.text)
        end
        return all_content       
    else      
      flash[:error] = 'Это не PDF файл' 
      return false
    end
  end
  
  def parse_file(contents)
    if contents[0].slice(/CLIENT\W+N\W+\w+/).to_s.empty? # проверка правильный рдф файл мы загрузили
      return false
    else
      client = contents[0].slice(/CLIENT\W+N\W+\w+/).slice(/\d+/).to_i
      bill = contents[0].slice(/BILL\WN\W+\w+/).slice(/\d+/).to_i
      n_pages_individual_detail = 0 # количество пропарсиный страниц individual_detail (в заданини первые 5)
      data_cellular_numbers = []      
      # создаем хеш с даными для заполнения полей individual_detail, первые елементы масивов - регулярки для 
      # поиска нужных данных 
      parse = {service_plan_name: [/Service Plan Name/], additional_local_airtime:  [/Additional Local Airtime/],
        long_distance_charges: [/Long Distance Charges/], data_and_other_services: [/Data and Other Services/],
        value_addded_services: [/Value Added Services/],saving: [/Total\W+Month's\W+Savings\W+\d+.\d+/],
        total_current_charges: [/Total Current Charges\W+\d+.\d+/]}
      contents.each do |content| # парсинг по страницам
        # exit_cellular_numbers - переход с поиска данных с таблицы cellular_number на таблицу individual_detail
        exit_cellular_numbers = content.scan(/I\WN\WD\WI\WV\WI\WD\WU\WA\WL\WD\WE\WT\WA\WI\WL/) 
        if exit_cellular_numbers.empty?
          # вытягиваем все данные для таблицы cellular_number      
          data_cellular_numbers += content.scan(/\w+\W+\d+\-\d+\-\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+\W+\d+\.\d+/)
        elsif !exit_cellular_numbers.empty? && n_pages_individual_detail < 5       
          if !content.slice(/C u r r e n t C h a r g e s - D e t a i l/).nil? # есть ли данные на странице для individual_detail
            n_pages_individual_detail += 1
            totals_individual_detail = [] # для вытягивание тоталов на странице
            totals_individual_detail = content.scan(/Total\W+\$ \d+.\d+/)
            totals_individual_detail.map! do |k| # вытягиваем или тоталов только числовое значение
              k.slice(/\d+.\d+/)
            end   
            n_totals_individual_detail = 0 # нужна для присваивания нужного значения нужному столбцу таблицы individual_detail
            parse.each_key do |key|
              if content.slice(parse[key][0]).nil? # если даных для столбца на странице нет то присв. - 0
                parse[key].push(0)
              elsif key == :saving || key == :total_current_charges  
                parse[key].push(content.slice(parse[key][0]).slice(/\d+.\d+/))
              else
                parse[key].push(totals_individual_detail[n_totals_individual_detail])
                n_totals_individual_detail += 1
              end
            end              
          end
        else n_pages_individual_detail >= 5       
          break       
        end
      end  
      data_cellular_numbers.map! do |i| # данные для таблицы cellular_number заганяем в масив
        i.split
      end
      parse.each_key do |key|  # удаляем регулярки, за ненадобностью
        parse[key].delete_at(0)
      end   
      # загоняем все нужные переменные в хеш для ретурна
      parse[:client] = client
      parse[:bill] =  bill
      parse[:data_cellular_numbers] = data_cellular_numbers
      return parse
    end  
  end

  def new_db_client(client, bill)
    client = Client.new(client_number:client, bill_number:bill )
  end

  def new_db_cellular_number(data_cellular_number)
    cellular_number = CellularNumber.new
    cellular_number.user = data_cellular_number[1]
    cellular_number.service_plan_price = data_cellular_number[2].to_f
    cellular_number.additional_local_airtime = data_cellular_number[3].to_f
    cellular_number.ld_and_roaming_charges = data_cellular_number[4].to_f
    cellular_number.data_voice_and_other = data_cellular_number[5].to_f
    cellular_number.other_frees = data_cellular_number[9].to_f
    cellular_number.gst = data_cellular_number[12].to_f
    cellular_number.subtotal = data_cellular_number[11].to_f
    cellular_number.total = data_cellular_number[13].to_f 
    return cellular_number  
  end

  def new_db_individual_detail(saving, total_current_charges, service_plan_name,
                               additional_local_airtime, long_distance_charges,
                               data_and_other_services, value_addded_services)
    individual_detail = IndividualDetail.new
    individual_detail.total_onths_savings = saving.to_f
    individual_detail.total = total_current_charges.to_f
    individual_detail.service_plan_name = service_plan_name
    individual_detail.additional_local_airtime = additional_local_airtime
    individual_detail.long_distance_charges = long_distance_charges
    individual_detail.data_and_other_services = data_and_other_services
    individual_detail.value_addded_services = value_addded_services
    return individual_detail
  end
end
