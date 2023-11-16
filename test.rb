require "google_drive" # gem install google_drive




class Column
  def initialize(table, column_index, ws)
    @table = table
    @column_index = column_index
    @ws = ws
  end

  def [](row_index)
    # +1 jer prvi red je header
    @table.data[row_index + 1][@column_index]
  end

  def []=(row_index, value)
    @ws[row_index+3, @column_index+1] = value.to_s
    @ws.save
    @table.data[row_index + 1][@column_index] = value.to_s
  end

  # vraca stringovni prikaz kolone
  def to_s
    values.join(", ")
  end

  # Pomocna metoda za preuzimanje vrednosti iz kolone
  def values
    @table.data.map { |row| row[@column_index] }
  end

  # dodato za 6. zadatak (sum i avg)
  def sum
    values.map(&:to_f).reduce(0.0, :+) # &:to_f -> pretvara string u float, reduce(0.0, :+) -> sabira sve elemente u arrayu, pocinje od 0.0
  end

  # dodato za 6. zadatak (sum i avg)
  def avg
    sum / values.size.to_f
  end

  def map
    values.map do |value|
      yield value
    end
  end

  def select
    values.select do |value|
      yield value
    end
  end

  def reduce(initial)
    values.reduce(initial) do |accumulator, value|
      yield accumulator, value
    end
  end

  def method_missing(name, *args, &block)
    string_name = name.to_s # saljem mu "red2" koji se pretvara u string
    row = @table.data.find { |r| r[@column_index].to_s == string_name }
  end



end



class Table
  include Enumerable # modul koji omogucava koriscenje metoda iz Enumerable modula (each, map, select, inject, ...)
  attr_reader :data # getter
  attr_accessor :ws # getter i setter

  def initialize(worksheet) # konstruktor
    @ws = worksheet
    @data = worksheet_to_array(worksheet) # u @data se upisuje array iz worksheet_to_array metode
    define_column_methods
  end

  private
  # Konvertuje worksheet u 2D array, iskljucujuci redove sa 'total', 'subtotal' ili prazne redove
  def worksheet_to_array(worksheet)
    array = []
    (1..worksheet.num_rows).each do |row_index|
      row = (1..worksheet.num_cols).map { |col_index| worksheet[row_index, col_index] }
      #next je kao continue u c
      next if row.all? { |cell| cell.to_s.strip.empty? } # task 10 - ako je cela vrsta prazna, preskoci je
      next if row.any? { |cell| cell.to_s.match?(/\b(total|subtotal)\b/i) } # task 7 - ako u vrsti postoji bar jedan total ili subtotal, preskoci je
      array << row
    end
    array
  end

  # Vraca red na osnovu indexa (2 task)
  public
  def row(index)
    raise "Row index out of bounds" if index < 1 || index > data.length # exception
    data[index - 1]
  end

  # Implementacija each metode za Enumerable (3rd task)
  def each
    data.each do |row|
      row.each do |cell|
        yield cell
      end
    end
  end



  # vraca kolonu na osnovu haedera [5 task a)]
  def [](header)
    header_index = data.first.index(header)
    raise "Column not found" unless header_index
    Column.new(self, header_index, @ws)
  end


# Returns column with header [6 task a)]
def define_column_methods
  # zelim da dobijem prvaKolona, drugaKolona, trecaKolona, ...
  headers = data.first.map do |header|
    header.split.map.with_index do |word, index| # pravi se ["Prva", "Kolona"] gde je "Prva" index 0, a "Kolona" index 1
      index == 0 ? word.downcase : word.capitalize # "Prva" se pretvara u "prva", a "Kolona" u "Kolona"
    end.join # na kraju se spaja u string "prvaKolona"
  end
  headers.each_with_index do |header, index|
    define_singleton_method(header) do # define_singleton_method - dodaje metodu na objekat
      Column.new(self, index, @ws)
    end
  end
end


end

session = GoogleDrive::Session.from_config("config.json")
ws = session.spreadsheet_by_key("1Y7V43g-p6iYNxjDLRFdVN2RFf2osKrgoa0V4NBImR88").worksheets[0]


table = Table.new(ws)

# PRVI TASK
puts "Prvi task: #{table.data.inspect}"

puts "\n"

# DRUGI TASK
puts "Drugi task: --- Row 1: #{table.row(1).inspect}" # inspect -> vraca string reprezentaciju objekta
puts "\n"

# TRECI TASK
puts "Treci task: --- Each:"
table.each do |cell|
  puts cell
end

# PETI TASK
puts "\n"
puts "Peti task: --- a) #{table["Prva Kolona"]}"
puts "Peti task: --- b) #{table["Prva Kolona"][2]}" # 1 - drugi element iz kolone (broj 1)
puts "Peti task: --- c) #{table["Prva Kolona"][2] = 256}" # 1 - drugi element iz kolone (broj 1), vrednost nije promenjena ako se ponovo printa cela tabela
puts "Cela tabela: #{table.data.inspect}"
puts "\n"

# SESTI TASK
puts "Sesti task: --- a) #{table.drugaKolona}"
puts "Sesti task: --- a) 1. ------(SUM) #{table.drugaKolona.sum}"
puts "Sesti task: --- a) 1. ------(AVG) #{table.drugaKolona.avg}"
puts "Sesti task: --- a) 1. ------(AVG) #{table.drugaKolona.avg}"

puts "Sesti task: --- a) 2. ------(t.cetvrtaKolona.red2) #{table.cetvrtaKolona.red2}"

puts "Sesti task: --- a) 3. ------(MAP) #{table.drugaKolona.map { |cell| cell.match?(/\A-?\d+\Z/) ? (cell.to_i + 1).to_s : cell }}" # ako je broj, dodaje 1, ako nije, vraca isti string
puts "Sesti task: --- a) 3. ------(SELECT) #{table.drugaKolona.select {|cell| cell.match?(/\A-?\d+\Z/) && cell.to_i.even? }}"
puts "Sesti task: --- a) 4. ------(REDUCE) #{table.drugaKolona.reduce(0) { |sum, cell| sum + cell.to_i }}"
