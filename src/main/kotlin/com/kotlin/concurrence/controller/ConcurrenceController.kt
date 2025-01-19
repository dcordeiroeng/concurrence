package com.kotlin.concurrence.controller

import org.slf4j.LoggerFactory
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.reactive.function.client.WebClient
import reactor.core.publisher.Mono
import reactor.core.scheduler.Schedulers
import java.time.Duration
import java.util.concurrent.ThreadLocalRandom
import java.util.concurrent.TimeoutException

@RestController
class ConcurrenceController {
    private val logger = LoggerFactory.getLogger(ConcurrenceController::class.java)
    private val webClient = WebClient.builder()
        .baseUrl("http://localhost:8080")
        .build()

    @GetMapping("in-order")
    fun getAllInOrder(): Mono<String> {
        val service1Response = callService1()
        val service2Response = callService2(mapOf())
        val aMono = getA("a")
        val bMono = getB("b")
        val cMono = getC("c")

        return aMono.flatMap { aResponse ->
            bMono.flatMap { bResponse ->
                cMono.map { cResponse ->
                    "$aResponse, \n$bResponse, \n$cResponse"
                }
            }
        }
    }

    @GetMapping("async-mono")
    fun getAllAsync(): Mono<String> {
        val service1Response = callService1()

        val aMono = getA(service1Response).subscribeOn(Schedulers.boundedElastic())
        val bMono = getB(service1Response).subscribeOn(Schedulers.boundedElastic())
        val cMono = getC(service1Response).subscribeOn(Schedulers.boundedElastic())

        return Mono.zip(aMono, bMono, cMono)
            .flatMap { tuple ->
                val responses = mapOf(
                    "aResponse" to tuple.getT1(),
                    "bResponse" to tuple.getT2(),
                    "cResponse" to tuple.getT3(),
                )
                Mono.fromCallable {
                    callService2(responses)
                }.subscribeOn(Schedulers.boundedElastic())
            }
    }

    private fun getA(parameter: String): Mono<String> {
        logger.info("getA received: $parameter")
        return webClient.get()
            .uri("http://localhost:8080/a")
            .retrieve()
            .bodyToMono(String::class.java)
            .timeout(Duration.ofSeconds(2))
            .doOnError(TimeoutException::class.java) {
                logger.error("Timeout occurred while calling /a", it)
            }
    }

    private fun getB(parameter: String): Mono<String> {
        logger.info("getB received: $parameter")
        return webClient.get()
            .uri("http://localhost:8080/b")
            .retrieve()
            .bodyToMono(String::class.java)
            .timeout(Duration.ofSeconds(2))
            .doOnError(TimeoutException::class.java) {
                logger.error("Timeout occurred while calling /b", it)
            }
    }

    private fun getC(parameter: String): Mono<String> {
        logger.info("getC received: $parameter")
        return webClient.get()
            .uri("http://localhost:8080/c")
            .retrieve()
            .bodyToMono(String::class.java)
            .timeout(Duration.ofSeconds(2))
            .doOnError(TimeoutException::class.java) {
                logger.error("Timeout occurred while calling /c", it)
            }
    }

    private fun callService1(): String {
//        Thread.sleep(ThreadLocalRandom.current().nextLong(100, 150))
        Thread.sleep(150)
        logger.info("Service1 data fetched")
        return "response"
    }

    private fun callService2(responses: Map<String, String>): String {
//        Thread.sleep(ThreadLocalRandom.current().nextLong(20, 50))
        Thread.sleep(50)
        logger.info("Service2 processed responses: $responses")
        return "Processed responses: $responses"
    }
}
