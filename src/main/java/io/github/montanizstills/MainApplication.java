package io.github.montanizstills;

import io.github.montanizstills.heygenAPI.HeygenEndpoints;
import io.github.montanizstills.heygenAPI.HeygenUtils;
import org.springframework.boot.SpringApplication;


import java.io.IOException;


public class MainApplication {

    public static void main(String[] args) throws IOException, InterruptedException {
//        SpringApplication.run(MainApplication.class, args);
        HeygenUtils heygenUtils = new HeygenUtils();
        heygenUtils.createAPIKey();


//        heygenUtils.simplePost(HeygenEndpoints.CREATE_VIDEO.getURL());

    }
}
