#
# This class is automatically generated by mig. DO NOT EDIT THIS FILE.
# This class implements a Python interface to the 'RoutMsg'
# message type.
#

import tinyos.message.Message

# The default size of this message type in bytes.
DEFAULT_MESSAGE_SIZE = 8

# The Active Message type associated with this message.
AM_TYPE = 1

class RoutMsg(tinyos.message.Message.Message):
    # Create a new RoutMsg of size 8.
    def __init__(self, data="", addr=None, gid=None, base_offset=0, data_length=8):
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
        s = "Message <RoutMsg> \n"
        try:
            s += "  [routing=0x%x]\n" % (self.get_routing())
        except:
            pass
        try:
            s += "  [overlap=0x%x]\n" % (self.get_overlap())
        except:
            pass
        try:
            s += "  [numNodes=0x%x]\n" % (self.get_numNodes())
        except:
            pass
        return s

    # Message-type-specific access methods appear below.

    #
    # Accessor methods for field: routing
    #   Field type: int
    #   Offset (bits): 0
    #   Size (bits): 32
    #

    #
    # Return whether the field 'routing' is signed (False).
    #
    def isSigned_routing(self):
        return False
    
    #
    # Return whether the field 'routing' is an array (False).
    #
    def isArray_routing(self):
        return False
    
    #
    # Return the offset (in bytes) of the field 'routing'
    #
    def offset_routing(self):
        return (0 / 8)
    
    #
    # Return the offset (in bits) of the field 'routing'
    #
    def offsetBits_routing(self):
        return 0
    
    #
    # Return the value (as a int) of the field 'routing'
    #
    def get_routing(self):
        return self.getSIntElement(self.offsetBits_routing(), 32, 1)
    
    #
    # Set the value of the field 'routing'
    #
    def set_routing(self, value):
        self.setSIntElement(self.offsetBits_routing(), 32, value, 1)
    
    #
    # Return the size, in bytes, of the field 'routing'
    #
    def size_routing(self):
        return (32 / 8)
    
    #
    # Return the size, in bits, of the field 'routing'
    #
    def sizeBits_routing(self):
        return 32
    
    #
    # Accessor methods for field: overlap
    #   Field type: short
    #   Offset (bits): 32
    #   Size (bits): 16
    #

    #
    # Return whether the field 'overlap' is signed (False).
    #
    def isSigned_overlap(self):
        return False
    
    #
    # Return whether the field 'overlap' is an array (False).
    #
    def isArray_overlap(self):
        return False
    
    #
    # Return the offset (in bytes) of the field 'overlap'
    #
    def offset_overlap(self):
        return (32 / 8)
    
    #
    # Return the offset (in bits) of the field 'overlap'
    #
    def offsetBits_overlap(self):
        return 32
    
    #
    # Return the value (as a short) of the field 'overlap'
    #
    def get_overlap(self):
        return self.getSIntElement(self.offsetBits_overlap(), 16, 1)
    
    #
    # Set the value of the field 'overlap'
    #
    def set_overlap(self, value):
        self.setSIntElement(self.offsetBits_overlap(), 16, value, 1)
    
    #
    # Return the size, in bytes, of the field 'overlap'
    #
    def size_overlap(self):
        return (16 / 8)
    
    #
    # Return the size, in bits, of the field 'overlap'
    #
    def sizeBits_overlap(self):
        return 16
    
    #
    # Accessor methods for field: numNodes
    #   Field type: short
    #   Offset (bits): 48
    #   Size (bits): 16
    #

    #
    # Return whether the field 'numNodes' is signed (False).
    #
    def isSigned_numNodes(self):
        return False
    
    #
    # Return whether the field 'numNodes' is an array (False).
    #
    def isArray_numNodes(self):
        return False
    
    #
    # Return the offset (in bytes) of the field 'numNodes'
    #
    def offset_numNodes(self):
        return (48 / 8)
    
    #
    # Return the offset (in bits) of the field 'numNodes'
    #
    def offsetBits_numNodes(self):
        return 48
    
    #
    # Return the value (as a short) of the field 'numNodes'
    #
    def get_numNodes(self):
        return self.getSIntElement(self.offsetBits_numNodes(), 16, 1)
    
    #
    # Set the value of the field 'numNodes'
    #
    def set_numNodes(self, value):
        self.setSIntElement(self.offsetBits_numNodes(), 16, value, 1)
    
    #
    # Return the size, in bytes, of the field 'numNodes'
    #
    def size_numNodes(self):
        return (16 / 8)
    
    #
    # Return the size, in bits, of the field 'numNodes'
    #
    def sizeBits_numNodes(self):
        return 16
    