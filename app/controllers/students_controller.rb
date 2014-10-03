class StudentsController < ApplicationController
  before_action :set_student, only: [:show, :edit, :update, :destroy]

  # GET /students
  # GET /students.json
  def index
    @students = Student.all
  end

  # GET /students/1
  # GET /students/1.json
  def show
  end

  # GET /students/new
  def new
    @student = Student.new
  end

  # GET /students/1/edit
  def edit
  end

  # POST /students
  # POST /students.json
  def create
    @student = Student.new(student_params)

    respond_to do |format|
      if @student.save
        format.html { redirect_to @student, notice: 'Student was successfully created.' }
        format.json { render :show, status: :created, location: @student }
      else
        format.html { render :new }
        format.json { render json: @student.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /students/1
  # PATCH/PUT /students/1.json
  def update
    respond_to do |format|
      if @student.update(student_params)
        format.html { redirect_to @student, notice: 'Student was successfully updated.' }
        format.json { render :show, status: :ok, location: @student }
      else
        format.html { render :edit }
        format.json { render json: @student.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /students/1
  # DELETE /students/1.json
  def destroy
    @student.destroy
    respond_to do |format|
      format.html { redirect_to students_url, notice: 'Student was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def import
    # Parse the student data
    student_data = params[:student_data] ? params[:student_data].read : ""

    # TODO: Don't assume first row is a header row. Detect it and skip if it's there.
    row_count = 0
    student_data.split(/[\r\n]/).each do |row|
      next if row.blank?
      row_count += 1

      # Skip the header row (e.g. first row) in the data
      next if row_count == 1

      parsed_row = row.split(/,/)
      s = Student.new(last_name: parsed_row[1], first_name: parsed_row[2], grade: parsed_row[3])
      s.save!
    end

    redirect_to students_url, notice: "#{row_count - 1} student records created."
  end

  def search
    # Search for students based on full-names and last-names that start with the search term.

    search_for = "#{params[:term]}%"
    @matches = Student.where("full_name ilike ? or last_name ilike ?", search_for, search_for).limit(10).pluck(:full_name)
    render json: @matches
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_student
      @student = Student.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def student_params
      params.require(:student).permit(:first_name, :last_name, :grade)
    end
end
