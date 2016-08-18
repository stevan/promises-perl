package Promises::Role::Promise;
# ABSTRACT: Role defining the methods available to a promise

use Moo::Role;

requires qw/
    then    
    catch   
    done    
    finally 
    status  
    result  

    is_unfulfilled 
    is_fulfilled   
    is_failed      

    is_in_progress 
    is_resolved    
    is_rejected    
/;

1;

__END__
