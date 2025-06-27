package test.java;

import  org.egovframe.rte.fdl.cryptography.EgovCryptoService;
import org.egovframe.rte.fdl.cryptography.EgovPasswordEncoder;
import org.springframework.beans.factory.annotation.Autowired;

public class Encryption {
	@Autowired
	private static EgovCryptoService egovCryptoService;
	
	@Autowired
	private EgovPasswordEncoder passwordEncoder;

	public static void main(String[] args) {
		EgovPasswordEncoder pe = new EgovPasswordEncoder();
		
		String str = pe.encryptPassword("asdf");
		System.out.println(str);
		System.out.println(pe.checkPassword("asdf", str));
	}

}
