module Saraid
  module Lox
    class Resolver
      include Visitor

      def initialize(interpreter)
        @interpreter = interpreter
        @scopes = []
        @current_function = nil
        @current_class = nil
      end
      attr_reader :interpreter, :scopes

      def visitBlockStmt(stmt)
        beginScope
        resolve stmt.statements
        endScope
        nil
      end

      def resolve(statements)
        case statements
        when Array then statements.each { resolve _1 }
        when Stmt, Expr then statements.accept(self)
        end
      end

      def beginScope
        @scopes << {}
      end

      def endScope
        @scopes.pop
      end

      def visitVarStmt(stmt)
        declare(stmt.name)
        resolve(stmt.initializer) if stmt.initializer
        define(stmt.name)
        nil
      end

      private def declare(name)
        return if @scopes.empty?

        scope = @scopes.last
        Lox.error(name, "Already a variable with this name in this scope.") if scope.key?(name.lexeme)
        scope[name.lexeme] = false
      end

      private def define(name)
        return if @scopes.empty?

        @scopes.last[name.lexeme] = true
      end

      def visitVariableExpr(expr)
        if scopes.any? && scopes.last[expr.name.lexeme] == false
          Lox.error(expr.name, "Can't read local variable in its own initializer.")
        end

        resolveLocal(expr, expr.name)
        nil
      end

      private def resolveLocal(expr, name)
        #require 'byebug'; byebug if name.lexeme == 'this'
        #index = @scopes.reverse.find_index { _1.key?(name.lexeme) }
        #interpreter.resolve(expr, scopes.size - 1 - index) if index

        # TODO: ARGGGGGGH
        i = @scopes.size - 1
        while i >= 0
          if @scopes[i].key?(name.lexeme)
            interpreter.resolve(expr, @scopes.size - 1 - i)
            return
          end
          i -= 1
        end
      end

      def visitAssignExpr(expr)
        resolve(expr.value)
        resolveLocal(expr, expr.name)
        nil
      end

      def visitFunctionStmt(stmt)
        declare(stmt.name)
        define(stmt.name)

        resolveFunction(stmt, :function)
        nil
      end

      private def resolveFunction(function, type)
        enclosing_function = @current_function
        @current_function = type

        beginScope
        function.params.each do |param|
          declare(param)
          define(param)
        end
        resolve(function.body)
        endScope

        @current_function = enclosing_function
      end

      def visitExpressionStmt(stmt)
        resolve(stmt.expression)
        nil
      end

      def visitIfStmt(stmt)
        resolve(stmt.condition)
        resolve(stmt.thenBranch)
        resolve(stmt.elseBranch) if stmt.elseBranch
        nil
      end

      def visitPrintStmt(stmt)
        resolve(stmt.expression)
        nil
      end

      def visitReturnStmt(stmt)
        Lox.error(stmt.keyword, "Can't return from top-level code.") if @current_function.nil?
        if stmt.value
          Lox.error(stmt.keyword, "Can't return a value from an initializer.") if @current_function == :initializer
          resolve(stmt.value) 
        end
        nil
      end

      def visitWhileStmt(stmt)
        resolve(stmt.condition)
        resolve(stmt.body)
        nil
      end

      def visitBinaryExpr(expr)
        resolve(expr.left)
        resolve(expr.right)
        nil
      end

      def visitCallExpr(expr)
        resolve(expr.callee)
        expr.arguments.each { resolve _1 }
        nil
      end

      def visitGroupingExpr(expr)
        resolve(expr.expression)
        nil
      end

      def visitLogicalExpr(expr)
        resolve(expr.left)
        resolve(expr.right)
        nil
      end

      def visitUnaryExpr(expr)
        resolve(expr.right)
        nil
      end

      def visitClassStmt(stmt)
        enclosing_class = @current_class
        @current_class = :class

        declare(stmt.name)
        define(stmt.name)

        if stmt.superclass
          if stmt.name.lexeme == stmt.superclass.name.lexeme
            Lox.error(stmt.superclass.name, "A class can't inherit from itself.");
          end
          resolve(stmt.superclass) 
        end

        beginScope
        @scopes.last['this'] = true
        stmt.methods.each do 
          declaration = _1.name.lexeme == 'init' ? :initializer : :method
          resolveFunction(_1, declaration)
        end
        endScope

        @current_class = enclosing_class
        nil
      end

      def visitGetExpr(expr)
        resolve(expr.object)
        nil
      end

      def visitSetExpr(expr)
        resolve(expr.value)
        resolve(expr.object)
        nil
      end

      def visitThisExpr(expr)
        if @current_class.nil?
          Lox.error(expr.keyword, "Can't use 'this' outside of a class.")
          return
        end
        resolveLocal(expr, expr.keyword)
        nil
      end
    end
  end
end
