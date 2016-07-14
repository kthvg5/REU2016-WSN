#
# This class is automatically generated by mig. DO NOT EDIT THIS FILE.
# This class implements a Python interface to the 'FloodMsg'
# message type.
#

import tinyos.message.Message

# The default size of this message type in bytes.
DEFAULT_MESSAGE_SIZE = 26

# The Active Message type associated with this message.
AM_TYPE = 2

class FloodMsg(tinyos.message.Message.Message):
    # Create a new FloodMsg of size 26.
    def __init__(self, data="", addr=None, gid=None, base_offset=0, data_length=26):
        tinyos.message.Message.Message.__init__(self, data, addr, gid, base_offset, data_length)
        self.amTypeSet(AM_TYPE)
    
    # Get AM_TYPE
    def get_amType(cls):
        return AM_TYPE
    
    get_amType = classmethod(get_amType)
    
    #
    # Return a String representation of this message. Includes the
    # message type name and the non-indexed field values.
    #
    def __str__(self):
        s = "Message <FloodMsg> \n"
        try:
            s += "  [sources=";
            for i in range(0, 10):
                s += "0x%x " % (self.getElement_sources(i) & 0xffff)
            s += "]\n";
        except:
            pass
        try:
            s += "  [temp=0x%x]\n" % (self.get_temp())
        except:
            pass
        try:
            s += "  [hum=0x%x]\n" % (self.get_hum())
        except:
            pass
        try:
            s += "  [wind=0x%x]\n" % (self.get_wind())
        except:
            pass
        return s

    # Message-type-specific access methods appear below.

    #
    # Accessor methods for field: sources
    #   Field type: int[]
    #   Offset (bits): 0
    #   Size of each element (bits): 16
    #

    #
    # Return whether the field 'sources' is signed (False).
    #
    def isSigned_sources(self):
        return False
    
    #
    # Return whether the field 'sources' is an array (True).
    #
    def isArray_sources(self):
        return True
    
    #
    # Return the offset (in bytes) of the field 'sources'
    #
    def offset_sources(self, index1):
        offset = 0
        if index1 < 0 or index1 >= 10:
            raise IndexError
        offset += 0 + index1 * 16
        return (offset / 8)
    
    #
    # Return the offset (in bits) of the field 'sources'
    #
    def offsetBits_sources(self, index1):
        offset = 0
        if index1 < 0 or index1 >= 10:
            raise IndexError
        offset += 0 + index1 * 16
        return offset
    
    #
    # Return the entire array 'sources' as a int[]
    #
    def get_sources(self):
        tmp = [None]*10
        for index0 in range (0, self.numElements_sources(0)):
                tmp[index0] = self.getElement_sources(index0)
        return tmp
    
    #
    # Set the contents of the array 'sources' from the given int[]
    #
    def set_sources(self, value):
        for index0 in range(0, len(value)):
            self.setElement_sources(index0, value[index0])

    #
    # Return an element (as a int) of the array 'sources'
    #
    def getElement_sources(self, index1):
        return self.getUIntElement(self.offsetBits_sources(index1), 16, 1)
    
    #
    # Set an element of the array 'sources'
    #
    def setElement_sources(self, index1, value):
        self.setUIntElement(self.offsetBits_sources(index1), 16, value, 1)
    
    #
    # Return the total size, in bytes, of the array 'sources'
    #
    def totalSize_sources(self):
        return (160 / 8)
    
    #
    # Return the total size, in bits, of the array 'sources'
    #
    def totalSizeBits_sources(self):
        return 160
    
    #
    # Return the size, in bytes, of each element of the array 'sources'
    #
    def elementSize_sources(self):
        return (16 / 8)
    
    #
    # Return the size, in bits, of each element of the array 'sources'
    #
    def elementSizeBits_sources(self):
        return 16
    
    #
    # Return the number of dimensions in the array 'sources'
    #
    def numDimensions_sources(self):
        return 1
    
    #
    # Return the number of elements in the array 'sources'
    #
    def numElements_sources():
        return 10
    
    #
    # Return the number of elements in the array 'sources'
    # for the given dimension.
    #
    def numElements_sources(self, dimension):
        array_dims = [ 10,  ]
        if dimension < 0 or dimension >= 1:
            raise IndexException
        if array_dims[dimension] == 0:
            raise IndexError
        return array_dims[dimension]
    
    #
    # Accessor methods for field: temp
    #   Field type: int
    #   Offset (bits): 160
    #   Size (bits): 16
    #

    #
    # Return whether the field 'temp' is signed (False).
    #
    def isSigned_temp(self):
        return False
    
    #
    # Return whether the field 'temp' is an array (False).
    #
    def isArray_temp(self):
        return False
    
    #
    # Return the offset (in bytes) of the field 'temp'
    #
    def offset_temp(self):
        return (160 / 8)
    
    #
    # Return the offset (in bits) of the field 'temp'
    #
    def offsetBits_temp(self):
        return 160
    
    #
    # Return the value (as a int) of the field 'temp'
    #
    def get_temp(self):
        return self.getUIntElement(self.offsetBits_temp(), 16, 1)
    
    #
    # Set the value of the field 'temp'
    #
    def set_temp(self, value):
        self.setUIntElement(self.offsetBits_temp(), 16, value, 1)
    
    #
    # Return the size, in bytes, of the field 'temp'
    #
    def size_temp(self):
        return (16 / 8)
    
    #
    # Return the size, in bits, of the field 'temp'
    #
    def sizeBits_temp(self):
        return 16
    
    #
    # Accessor methods for field: hum
    #   Field type: int
    #   Offset (bits): 176
    #   Size (bits): 16
    #

    #
    # Return whether the field 'hum' is signed (False).
    #
    def isSigned_hum(self):
        return False
    
    #
    # Return whether the field 'hum' is an array (False).
    #
    def isArray_hum(self):
        return False
    
    #
    # Return the offset (in bytes) of the field 'hum'
    #
    def offset_hum(self):
        return (176 / 8)
    
    #
    # Return the offset (in bits) of the field 'hum'
    #
    def offsetBits_hum(self):
        return 176
    
    #
    # Return the value (as a int) of the field 'hum'
    #
    def get_hum(self):
        return self.getUIntElement(self.offsetBits_hum(), 16, 1)
    
    #
    # Set the value of the field 'hum'
    #
    def set_hum(self, value):
        self.setUIntElement(self.offsetBits_hum(), 16, value, 1)
    
    #
    # Return the size, in bytes, of the field 'hum'
    #
    def size_hum(self):
        return (16 / 8)
    
    #
    # Return the size, in bits, of the field 'hum'
    #
    def sizeBits_hum(self):
        return 16
    
    #
    # Accessor methods for field: wind
    #   Field type: int
    #   Offset (bits): 192
    #   Size (bits): 16
    #

    #
    # Return whether the field 'wind' is signed (False).
    #
    def isSigned_wind(self):
        return False
    
    #
    # Return whether the field 'wind' is an array (False).
    #
    def isArray_wind(self):
        return False
    
    #
    # Return the offset (in bytes) of the field 'wind'
    #
    def offset_wind(self):
        return (192 / 8)
    
    #
    # Return the offset (in bits) of the field 'wind'
    #
    def offsetBits_wind(self):
        return 192
    
    #
    # Return the value (as a int) of the field 'wind'
    #
    def get_wind(self):
        return self.getUIntElement(self.offsetBits_wind(), 16, 1)
    
    #
    # Set the value of the field 'wind'
    #
    def set_wind(self, value):
        self.setUIntElement(self.offsetBits_wind(), 16, value, 1)
    
    #
    # Return the size, in bytes, of the field 'wind'
    #
    def size_wind(self):
        return (16 / 8)
    
    #
    # Return the size, in bits, of the field 'wind'
    #
    def sizeBits_wind(self):
        return 16
    
