require 'sqlite3'

##
# This class represents an object embedded in an AppleNote.
class AppleNotesEmbeddedObject

  attr_accessor :primary_key,
                :uuid,
                :type,
                :filepath,
                :filename,
                :backup_location,
                :parent

  ##
  # Creates a new AppleNotesEmbeddedObject. 
  # Expects an Integer +primary_key+ from ZICCLOUDSYNCINGOBJECT.Z_PK, String +uuid+ from ZICCLOUDSYNCINGOBJECT.ZIDENTIFIER, 
  # String +uti+ from ZICCLOUDSYNCINGOBJECT.ZTYPEUIT, and AppleNote +note+ object representing the parent AppleNote.
  def initialize(primary_key, uuid, uti, note)
    # Set this folder's variables
    @primary_key = primary_key
    @uuid = uuid
    @type = uti
    @note = note
    @backup = @note.backup
    @database = @note.database
    @filepath = ""
    @filename = ""
    @backup_location = nil
  
    # Create an Array to hold Thumbnails and add them
    @thumbnails = Array.new
    search_and_add_thumbnails

    # Create an Array to hold child objects, such as for a gallery
    @child_objects = Array.new
  end

  ##
  # This method adds a +child_object+ to this object.
  def add_child(child_object)
    child_object.parent = self # Make sure the parent is set
    @child_objects.push(child_object)
  end

  ##
  # This method queries ZICCLOUDSYNCINGOBJECT to find any thumbnails for 
  # this object. Each one it finds, it adds to the thumbnails Array.
  def search_and_add_thumbnails
    @thumbnails = Array.new
    @database.execute("SELECT ZICCLOUDSYNCINGOBJECT.Z_PK, ZICCLOUDSYNCINGOBJECT.ZIDENTIFIER, " +
                      "ZICCLOUDSYNCINGOBJECT.ZHEIGHT, ZICCLOUDSYNCINGOBJECT.ZWIDTH " + 
                      "FROM ZICCLOUDSYNCINGOBJECT " + 
                      "WHERE ZATTACHMENT=?",
                      @primary_key) do |row|
      tmp_thumbnail = AppleNotesEmbeddedThumbnail.new(row["Z_PK"], 
                                                      row["ZIDENTIFIER"], 
                                                      "thumbnail", 
                                                      @note, 
                                                      @backup,
                                                      row["ZHEIGHT"],
                                                      row["ZWIDTH"],
                                                      self)
      @thumbnails.push(tmp_thumbnail)
    end
  end


  ##
  # This method just returns a readable String for the object.
  # By default it just lists the +type+ and +uuid+. Subclasses 
  # should override this.
  def to_s
    "Embedded Object #{@type}: #{@uuid}"
  end

  ##
  # By default this returns its own +uuid+. 
  # Subclasses will override this if they have other pointers to media objects.
  def get_media_uuid
    @uuid
  end

  ##
  # By default this returns its own +filepath+. 
  # Subclasses will override this if they have other pointers to media objects.
  def get_media_filepath
    @filepath
  end

  ##
  # By default this returns its own +filename+. 
  # Subclasses will override this if they have other pointers to media objects.
  def get_media_filename
    @filename
  end

  ##
  # This method returns either nil, if there is no parent object, 
  # or the parent object's primary_key.
  def get_parent_primary_key
    return nil if !@parent
    return @parent.primary_key
  end

  ##
  # Class method to return an Array of the headers used on CSVs for this class
  def self.to_csv_headers
    ["Object Primary Key", 
     "Note ID",
     "Parent Object ID",
     "Object UUID", 
     "Object Type",
     "Object Filename",
     "Object Filepath on Phone",
     "Object Filepath on Computer"]
  end

  ##
  # This method returns an Array of the fields used in CSVs for this class
  # Currently spits out the +primary_key+, AppleNote +note_id+, AppleNotesEmbeddedObject parent +primary_key+, 
  # +uuid+, +type+, +filepath+, +filename+, and +backup_location+  on the computer. Also computes these for 
  # any children and thumbnails.
  def to_csv
    to_return =[[@primary_key, 
                   @note.note_id,
                   get_parent_primary_key,
                   @uuid, 
                   @type,
                   @filename,
                   @filepath,
                   @backup_location]]

    # Add in any child objects
    @child_objects.each do |child_object|
      to_return += child_object.to_csv
    end

    # Add in any thumbnails
    @thumbnails.each do |thumbnail|
      to_return += thumbnail.to_csv
    end

    return to_return
  end

  ##
  # This method generates the HTML to be embedded into an AppleNote's HTML.
  def generate_html
    return self.to_s
  end

end
