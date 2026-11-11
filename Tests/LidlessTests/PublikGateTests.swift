import XCTest

/// The publik module (Sources/Lidless/Publik.swift): the slug the publik scan
/// reads, no AI, and the words of the gate, which are the same in every publik
/// app (publikhq.com/sdk/publik.swift.md). Nothing here touches the network or
/// the credential file.
final class PublikGateTests: XCTestCase {

    func testTheModuleNamesThisListingAndUsesNoAI() {
        XCTAssertEqual(Publik.appSlug, "lidless")
        XCTAssertFalse(Publik.usesAI, "Lidless calls no model: the gate shows only the sign-in screen")
        XCTAssertTrue(Publik.credentialURL.path.hasSuffix("/publik/apps/lidless.json"))
        XCTAssertFalse(Publik.appVersion.hasPrefix("v"), "the version goes out without a leading v")
    }

    func testTheSignInScreenHasTheContractWords() {
        let screen = Publik.gateScreen("sign_in")
        XCTAssertEqual(screen.title, "Sign in with publik")
        XCTAssertEqual(screen.body, "This app uses your publik account. Click Sign in with publik, then sign in in your browser. This window continues when you are signed in.")
        XCTAssertNil(screen.note)
        XCTAssertEqual(screen.buttons.map { $0.label }, ["Sign in with publik"])
        XCTAssertEqual(screen.buttons.map { $0.action }, ["sign_in"])

        let waiting = Publik.gateScreen("sign_in", note: "Waiting for you to sign in in your browser.")
        XCTAssertEqual(waiting.note, "Waiting for you to sign in in your browser.")
    }

    func testTheUnreachableScreenOffersRetryOnly() {
        let screen = Publik.gateScreen("unreachable")
        XCTAssertEqual(screen.title, "Sign in with publik")
        XCTAssertEqual(screen.body, "publik is not reachable. Check your connection.")
        XCTAssertEqual(screen.buttons.map { $0.label }, ["Retry"])
        XCTAssertEqual(screen.buttons.map { $0.action }, ["retry"])
        // A message from publik replaces the connection line.
        XCTAssertEqual(Publik.gateScreen("unreachable", message: "This key is not valid.").body, "This key is not valid.")
    }

    func testThePlanScreensKeepTheContractWords() {
        // Lidless never shows them (usesAI is false), but the module's words
        // stay the contract's, so a copy into an app with AI is right at once.
        var wallet = Publik.Wallet(claimed: true, claimURL: nil, handle: "mann", planKind: "none", planLabel: nil, balanceMicros: 0, topUpURL: "https://publikhq.com/wallet")
        let choose = Publik.gateScreen("choose", wallet)
        XCTAssertEqual(choose.title, "Choose how to pay for AI")
        XCTAssertEqual(choose.body, "You are signed in as @mann. This app uses AI. Get a publik plan, or use your own key.")
        XCTAssertEqual(choose.buttons.map { $0.label }, ["Get a plan", "Use my own key"])

        wallet.planKind = "plan"
        wallet.planLabel = "Plus"
        let connect = Publik.gateScreen("choose", wallet)
        XCTAssertEqual(connect.title, "Connect your plan")
        XCTAssertEqual(connect.body, "You are signed in as @mann. Your plan: Plus. Connect it to use AI in this app, or use your own key.")
        XCTAssertEqual(connect.buttons.map { $0.label }, ["Connect your plan", "Use my own key"])
        XCTAssertEqual(connect.buttons.map { $0.action }, ["connect", "own_key"])
    }

    func testA402IsTheServersMessageAndOneLink() {
        let body = Data(#"{"error":{"type":"insufficient_credit","message":"Add a plan to continue.","top_up_url":"https://publikhq.com/wallet?top_up=1"}}"#.utf8)
        let parsed = Publik.topUpURLFrom402(body)
        XCTAssertEqual(parsed.message, "Add a plan to continue.")
        XCTAssertEqual(parsed.url?.absoluteString, "https://publikhq.com/wallet?top_up=1")
        XCTAssertNil(Publik.topUpURLFrom402(Data("{}".utf8)).url)
    }
}
