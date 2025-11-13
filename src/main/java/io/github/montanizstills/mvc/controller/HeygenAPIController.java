package io.github.montanizstills.mvc.controller;

import io.github.montanizstills.heygenAPI.HeygenEndpoints;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;


@RestController
public class HeygenAPIController {
    @RequestMapping(path = HeygenEndpoints.DELETE_VIDEO, method = RequestMethod.POST)
    public ResponseEntity<String> deleteVideo(@RequestParam String asset_id) {
        final String responseBody = ""; //= service.create(person);
//        HttpClient client = HttpClient.newHttpClient();
//        HttpRequest request = HttpRequest.newBuilder()
//                .uri(URI.create(HeygenEndpoints.USER_DATA.getURL()))
//                .POST(HttpRequest.BodyPublishers.ofString("body"))
//                .build();
        final ResponseEntity<String> responseEntity = new ResponseEntity<>(responseBody, HttpStatus.OK);
        return responseEntity;
    }

    @Autowired
    public HeygenAPIController() {
    }
}