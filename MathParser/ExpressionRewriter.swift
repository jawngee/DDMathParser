//
//  ExpressionRewriter.swift
//  DDMathParser
//
//  Created by Dave DeLong on 8/25/15.
//
//

import Foundation

public struct ExpressionRewriter {
    private var rules: Array<RewriteRule>
    
    public static let `default` = ExpressionRewriter(rules: RewriteRule.defaultRules)
    
    public init(rules: Array<RewriteRule>) {
        self.rules = rules
    }
    
    public mutating func addRule(_ rule: RewriteRule) {
        rules.append(rule)
    }
    
    public func rewriteExpression(_ expression: Expression, substitutions: Substitutions = [:], evaluator: Evaluator = Evaluator.default) -> Expression {
        
        var tmp = expression
        var iterationCount = 0
        
        repeat {
            var changed = false
            
            for rule in rules {
                let rewritten = rewrite(tmp, usingRule: rule, substitutions: substitutions, evaluator: evaluator)
                if rewritten != tmp {
                    changed = true
                    tmp = rewritten
                }
            }
        
            if changed == false { break }
            iterationCount += 1
            
        } while iterationCount < 256
        
        if iterationCount >= 256 {
            NSLog("replacement limit reached")
        }
        
        return tmp
    }
    
    private func rewrite(_ expression: Expression, usingRule rule: RewriteRule, substitutions: Substitutions, evaluator: Evaluator) -> Expression {
        
        let simplified = expression.simplify(substitutions, evaluator: evaluator)
        
        let rewritten = rule.rewrite(simplified, substitutions: substitutions, evaluator: evaluator)
        if rewritten != expression { return rewritten }
        
        guard case let .function(f, args) = rewritten.kind else { return rewritten }
        
        let newArgs = args.map { rewrite($0, usingRule: rule, substitutions: substitutions, evaluator: evaluator) }
        
        // if nothing changed, reture
        guard args != newArgs else { return rewritten }
        
        return Expression(kind: .function(f, newArgs), range: rewritten.range)
    }
}
