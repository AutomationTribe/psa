# Personal Safety Platform — Stage 1 Product Discovery

Date: 29 September 2026. Status: Desk discovery complete; field validation outstanding. Owner: Lead AI. Geography: Nigeria first, later selected African markets.

## 1. Discovery brief

An Android and iPhone personal safety service for individuals and families, students, and commuters. Users choose trusted contacts, can raise manual SOS or missed-checkpoint alerts, choose ongoing or emergency-only location sharing, grant named contacts the right to request their location, schedule a fake call, and capture audio during SOS. A company team monitors and manages incidents. Partner platforms integrate the same alert and response capabilities through APIs. Approved additions: acknowledgement/escalation, location freshness and accuracy, practice mode, and consent/access history.

The product promise should be: fast, understandable escalation using the best location the device or caller can provide, with an honest timestamp and accuracy. It must never promise exact live location, guaranteed SMS delivery, rescue, or always-on sensing.

## 2. Segments and jobs to validate

| Segment | Likely job | Proposed initial use case | Unknown to test |
|---|---|---|---|
| Individuals/families | Know a loved one needs help and where to begin looking | Timed journey/check-in, trusted-circle SOS | Will contacts answer and act? What sharing modes are acceptable? |
| Students | Signal danger on campus or journeys | Missed arrival and discreet SOS | Are institutions willing and able to receive escalations? |
| Commuters | Protect a trip through variable connectivity | Start/end trip, missed checkpoint, last known location | Which triggers have acceptable false-alarm rates? |
| Partner platforms | Add safety and response without operating a control room | Consent-linked user enrolment, create/update/cancel incident, status callbacks | Which partner verticals pay, and who owns end-user support and consent? |

Recommended pilot wedge (hypothesis, not approved prioritization): commuter journeys and student travel in one Nigerian city, with trusted circles and a small staffed response trial. This gives a bounded way to measure checkpoint reliability and operator workload. Partner API should be designed as a core distribution channel, but not offered as a rescue guarantee before the response process works end to end.

## 3. Competitor scan (published claims, not independent performance tests)

| Product | Advertised capabilities | Discovery implication |
|---|---|---|
| AMBA, Nigeria | Safe Circle, location/audio SOS, trips, organization response dashboard | The basic app-plus-dashboard bundle is already offered. https://www.amba.africa/ |
| Urikaa, Nigeria | Trusted contacts, live location, check-ins and trip tracking | Checkpoints and circle sharing are established expectations. https://www.urikaa.org/ |
| Caritas Hopeline, Nigeria | SOS, response teams and a USSD access claim | USSD is a credible channel to investigate, with its real coverage and location behavior unverified. https://play.google.com/store/apps/details?id=org.ccfng.hopeline |
| Life360 | Circle SOS alerts with location | Family trust and recipient experience need particular attention. https://support.life360.com/hc/en-us/articles/23053474049687-SOS-Alerts |
| Noonlight, outside Nigeria | Dispatch API and human monitoring | Partner API plus response operations is an established category; Nigeria-specific operations are the opportunity to validate. https://www.noonlight.com/products/dispatch-api |

No claim of competitor delivery speed, commercial traction, or actual rescue coverage has been verified here.

## 4. Feasibility and safety findings

1. **Location and battery.** Explore low-power significant-change/region monitoring or geofencing when idle, increase location frequency during an active trip/SOS, and store/send the last verified fix with timestamp and accuracy. Apple documents lower-power significant-change service; Android recommends battery-aware geofencing and limits background location updates. Background permission and device state vary. Benchmarks on representative Nigerian phones are needed before promising frequency or battery targets. Sources: https://developer.apple.com/documentation/corelocation/getting-the-current-location-of-a-device ; https://developer.android.com/develop/sensors-and-location/location/background ; https://developer.android.com/develop/sensors-and-location/location/battery
2. **SMS.** iPhone's MessageUI exposes a user-operated composer, so unattended SOS SMS should be evaluated through a backend SMS provider when the app has data. Android's direct SEND_SMS emergency exception may be possible but requires Google Play declaration and approval. A phone with no data can fail to reach a backend; direct-device fallback differs by platform. Do not treat push, SMS or a provider's acceptance as proof of receipt. Sources: https://developer.apple.com/documentation/messageui/mfmessagecomposeviewcontroller ; https://support.google.com/googleplay/android-developer/answer/10208820
3. **USSD from another phone.** Investigate a telecom/aggregator-provided short code, identity verification under duress, caller location input, and whether operator-supplied approximate network location can lawfully be obtained. A dial from another device cannot obtain GPS from the user's absent phone by itself. Treat USSD as an alert initiation channel with possibly unknown caller location until proven otherwise. NCC describes USSD as a value-added service and sets requirements for short-code applications and aggregator arrangements. Sources: https://consumer.ncc.gov.ng/articles/113-understanding-value-added-services-vas-in-nigerias-telecom-industry ; https://ncc.gov.ng/industry/licensing/licensing-application-process
4. **Operations.** Define staffing hours, acknowledgement time, escalation rules, failed-contact handling, incident evidence and handoff, and relationships with credible responders. Dashboard access to live locations needs least privilege and audited case-based access. No claim of automatic official dispatch without a validated agreement and workflow.
5. **Privacy and abuse.** Always-on location, relative queries and partner APIs could enable stalking or misuse. Require explicit, revocable, person-specific sharing; access history; secure contact onboarding; operator access controls; and tightly scoped retention. Determine controller/processor responsibilities with partners and get Nigerian privacy review before launch. Source: https://ndpc.gov.ng/faqs/
6. **Audio and fake call.** Test platform background behavior and local legal/privacy requirements. Avoid telling users recording is active unless capture has actually started; design an honest failure state.

## 5. Partner API product questions

Evaluate partner categories such as campus apps, ride-hailing/mobility, transport, employee travel and estate apps. Needed product capabilities likely include partner authentication; verified consent and revocation; emergency identity/profile linking; idempotent incident creation; location updates with source/time/accuracy; incident status and acknowledgement; signed callbacks; sandbox/test incidents; rate limits; audit trail; and operational SLA definition. These are candidate requirements, not an approved API design.

Key ownership decision: who collects location and consent (partner or our app), who contacts the user/relatives, and who pays for monitoring and SMS? No partner should be able to query a person merely by knowing their phone number.

## 6. Validation plan and exit review

Run 12–18 structured interviews spanning three consumer segments, plus 5–8 partner/operator conversations. Observe actual contact response and checkpoint expectations. Do supervised drills on low-end and midrange Android phones and iPhones across weak-data, no-data, GPS-obstructed, low-battery, backgrounded and phone-off conditions. Record trigger-to-operator time, alert delivery, location age/accuracy, false alarms and battery drain compared with an idle baseline. Verify a USSD provider's live demo, commercial terms, network reach, caller identity and location limitations. Test staffing and escalation scripts with a small consented pilot.

Stage review: the concept and discovery risks are clear; market willingness, response economics, technical reliability, and telecom feasibility are not yet validated. Stage 2 product definition should label these as hypotheses and avoid promising outcomes that have not been measured. Major unresolved choice: pilot segment/city and monitoring coverage hours. The desk-discovery output is internally consistent and sufficient for a provisional product definition, subject to those explicit assumptions.
