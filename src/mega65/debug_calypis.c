

void debug_msg (char* msg){
    
    char the_char;

    while (*msg) {
      the_char = *msg;

      __asm volatile (
            " sta 0xd643\n"
            " clv\n"
            : // no output operands 
            : "Ka"(the_char) //input operands
            : "a" //clobber list 
      );
      
      msg++;
    }

    // clearing Z seems to fix occasional xemu freeze. Why?	
    __asm volatile (
        " lda #0x0d\n"
			  " sta 0xd643\n"
			  " clv\n"
			  " lda #0x0a\n"
        " sta 0xd643\n"
			  " clv\n"
			  " ldz #0\n"
        // : no output operands 
        // : no input operands
        // : no  clobber list 
        );

}


void debug_char(char the_char){

      __asm volatile (
            " sta 0xd643\n"
            " clv\n"
            : // no output operands 
            : "Ka"(the_char) //input operands
            : "a" //clobber list 
      );

    // clearing Z seems to fix occasional xemu freeze. Why?	
    __asm volatile (
        " lda #0x0d\n"
			  " sta 0xd643\n"
			  " clv\n"
			  " lda #0x0a\n"
        " sta 0xd643\n"
			  " clv\n"
			  " ldz #0\n"
        // : no output operands 
        // : no input operands
        // : no  clobber list 
        );

}